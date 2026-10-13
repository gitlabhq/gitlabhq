# frozen_string_literal: true

module Import
  module Github
    # Mints a short-lived installation token immediately before provider access.
    #
    # The returned value redacts itself from inspection and must not be put in a
    # model, cache record, URL, log payload, or background-job argument. Callers
    # are responsible for deciding whether an installation is one they should be
    # talking to before asking this service for a token.
    class InstallationTokenService
      include ApiRequest

      # Provider IDs must remain representable by the persisted bigint identity column.
      MAX_REPOSITORY_ID = Gitlab::Database::MAX_BIGINT_VALUE

      # GitHub tokens last one hour; caching stops short of the real expiry so a
      # cached token is never handed out with only seconds left to use it.
      TOKEN_CACHE_EXPIRY_BUFFER = 1.minute

      # Every installation credential is downscoped to this layer's fixed read-only
      # provider contract, even when the App itself was configured with writes.
      READ_ONLY_PERMISSIONS = {
        'metadata' => 'read',
        'contents' => 'read',
        'issues' => 'read',
        'pull_requests' => 'read',
        'administration' => 'read'
      }.freeze

      ConfigurationError = Class.new(StandardError)
      TokenRequestError = Class.new(StandardError)

      REPOSITORY_NOT_SELECTED_MESSAGE = 'GitHub App no longer has access to the connected repository'
      RepositoryNotSelectedError = Class.new(StandardError)

      class Token
        attr_reader :value, :expires_at

        def initialize(value:, expires_at:)
          @value = value
          @expires_at = expires_at
        end

        def inspect
          "#<#{self.class.name} expires_at=#{expires_at.iso8601}>"
        end
      end

      def initialize(installation_id, configuration: Configuration.new, jwt_service: nil)
        @installation_id = installation_id
        @configuration = configuration
        @jwt_service = jwt_service || AppJwtService.new(configuration: configuration)
      end

      # Returns a redacting Token value or raises a sanitized provider error.
      # An explicit repository ID narrows the token to that stable provider
      # identity and makes one fixed-origin provider request; neither scope
      # nor token is persisted.
      #
      # The minted token is cached encrypted in Redis, keyed by installation and
      # repository scope, until shortly before its provider-issued expiry. GitHub
      # installation tokens live for one hour, so a job started after another job
      # already minted a token for the same scope reuses it instead of making a
      # fresh request.
      #
      # @param repository_id [Integer, nil] a unique positive ID, or nil for full installation access
      # @param force_refresh [Boolean] mint a fresh token even if one is already cached for this scope
      # @return [Token] a credential that redacts itself from inspection
      # @raise [ConfigurationError] when credentials or the requested scope are invalid
      # @raise [RepositoryNotSelectedError] when GitHub rejects an explicit scope
      # @raise [Gitlab::GithubImport::RateLimitError] when GitHub explicitly reports exhausted request capacity
      # @raise [TokenRequestError] when transport or response validation fails
      def execute(repository_id: nil, force_refresh: false)
        normalized_repository_id = normalize_repository_id(repository_id)
        key = cache_key(normalized_repository_id)

        Gitlab::Cache::Import::Caching.del(key) if force_refresh

        cached_token(key) || mint_and_cache_token(key, repository_id: normalized_repository_id)
      end

      private

      attr_reader :installation_id, :configuration, :jwt_service

      def cache_key(repository_id)
        "import_sync_github_installation_token:#{installation_id}:#{repository_id}"
      end

      def cached_token(key)
        raw = Gitlab::Cache::Import::Caching.read(key, refresh: false)
        return unless raw

        data = Gitlab::Json::SafeParser.parse(raw)
        value = Gitlab::CryptoHelper.aes256_gcm_decrypt(data['value'])
        Token.new(value: value, expires_at: Time.iso8601(data['expires_at']))
      rescue JSON::ParserError, ArgumentError, TypeError, OpenSSL::Cipher::CipherError
        nil
      end

      def mint_and_cache_token(key, repository_id:)
        token = request_token(repository_id: repository_id)
        cache_token(key, token)
        token
      end

      # Caches the token only for the time it remains valid, minus a safety
      # buffer. A token minted with less than the buffer remaining is used
      # once but not cached, so the next call mints a fresh one instead of
      # reusing a value that could expire mid-request.
      def cache_token(key, token)
        ttl = (token.expires_at - Time.current - TOKEN_CACHE_EXPIRY_BUFFER).to_i
        return if ttl <= 0

        encrypted_value = Gitlab::CryptoHelper.aes256_gcm_encrypt(token.value)
        serialized = Gitlab::Json.generate(value: encrypted_value, expires_at: token.expires_at.iso8601)
        Gitlab::Cache::Import::Caching.write(key, serialized, timeout: ttl)
      end

      # Performs the fixed-origin token request and returns only a redacting value.
      # Transport, provider, and malformed-response failures raise sanitized errors.
      #
      # @param repository_id [Integer, nil] already-normalized provider scope
      # @return [Token] a short-lived credential without repository metadata
      # @raise [RepositoryNotSelectedError] for a scoped HTTP 422 response
      # @raise [Gitlab::GithubImport::RateLimitError] when GitHub explicitly reports exhausted request capacity
      # @raise [ConfigurationError, TokenRequestError] for all other local or provider failures
      def request_token(repository_id: nil)
        unless configuration.app_id && configuration.private_key
          raise ConfigurationError, 'GitHub App credentials are not configured'
        end

        response = Gitlab::HTTP.post(
          token_url,
          headers: headers,
          body: request_body(repository_id),
          timeout: 30,
          follow_redirects: false
        )

        if rate_limited_response?(response)
          raise Gitlab::GithubImport::RateLimitError, 'GitHub installation token request was rate limited'
        end

        raise RepositoryNotSelectedError, REPOSITORY_NOT_SELECTED_MESSAGE if repository_id && response.code.to_i == 422

        unless response.success?
          raise TokenRequestError, "GitHub installation token request failed (HTTP #{response.code})"
        end

        value = response['token'].presence
        expires_at = Time.iso8601(response['expires_at'].to_s)
        raise TokenRequestError, 'GitHub installation token response was incomplete' unless value

        Token.new(value: value, expires_at: expires_at)
      rescue *Gitlab::HTTP::HTTP_ERRORS => e
        raise TokenRequestError, "GitHub installation token request failed (#{e.class.name})"
      rescue ArgumentError
        raise TokenRequestError, 'GitHub installation token response was incomplete'
      end

      # Validates the documented provider limits before any scoped credential
      # request. Nil deliberately retains the legacy full-installation token.
      #
      # @param repository_id [Object] proposed provider scope
      # @return [Integer, nil] the validated ID, or nil for full access
      # @raise [ConfigurationError] when the explicit scope is malformed or out of range
      def normalize_repository_id(repository_id)
        return unless repository_id

        valid = repository_id.is_a?(Integer) && repository_id > 0 && repository_id <= MAX_REPOSITORY_ID
        raise ConfigurationError, 'GitHub App repository token scope is invalid' unless valid

        repository_id
      end

      # Serializes only the provider's token request. The repository identity is
      # never attached to the returned token or a persisted/loggable value.
      #
      # @param repository_id [Integer, nil] normalized provider scope
      # @return [String] fixed JSON request body containing no installation token
      def request_body(repository_id)
        body = { permissions: READ_ONLY_PERMISSIONS }
        body[:repository_ids] = [repository_id] if repository_id

        Gitlab::Json.generate(body)
      end

      # Distinguishes explicit provider throttling from ordinary authorization
      # failures without retaining response details. GitHub reports primary or
      # secondary limits as 429, or as 403 with Retry-After/zero remaining.
      def rate_limited_response?(response)
        status = response.code.to_i
        return true if status == 429
        return false unless status == 403

        headers = response.headers
        headers['Retry-After'].present? || headers['X-RateLimit-Remaining'].to_s == '0'
      rescue NoMethodError, TypeError
        false
      end

      def token_url
        "#{API_ROOT}/app/installations/#{positive_installation_id}/access_tokens"
      end

      def positive_installation_id
        integer = Integer(installation_id.to_s, 10)
        raise ConfigurationError, 'GitHub App installation ID is invalid' unless integer > 0

        integer
      rescue ArgumentError, TypeError
        raise ConfigurationError, 'GitHub App installation ID is invalid'
      end

      def headers
        {
          'Accept' => 'application/vnd.github+json',
          'Authorization' => "Bearer #{jwt_service.execute}",
          'Content-Type' => 'application/json',
          'User-Agent' => "GitLab/#{Gitlab::VERSION}",
          'X-GitHub-Api-Version' => API_VERSION
        }
      end
    end
  end
end
