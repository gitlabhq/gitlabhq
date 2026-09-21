# frozen_string_literal: true

module Import
  module Github
    # Reads GitHub App metadata with an App JWT and returns only parsed provider data.
    class AppApiClient
      include ApiRequest

      REPOSITORY_PATH_SEGMENT_PATTERN = /\A[0-9A-Za-z_.-]+\z/
      INVALID_REPOSITORY_PATH_SEGMENTS = %w[. ..].freeze

      ProviderError = Class.new(StandardError)
      RateLimitError = Class.new(ProviderError)
      InstallationNotFoundError = Class.new(ProviderError)
      RepositoryInstallationNotFoundError = Class.new(ProviderError)

      def initialize(configuration: Configuration.new, jwt_service: nil)
        @configuration = configuration
        @jwt_service = jwt_service || AppJwtService.new(configuration: configuration)
      end

      def application
        get('/app')
      end

      def installation(installation_id)
        get(
          "/app/installations/#{positive_integer(installation_id)}",
          not_found_error: InstallationNotFoundError
        )
      rescue ArgumentError, TypeError
        raise ProviderError, 'GitHub App request failed'
      end

      # Resolves the App installation selected for one durable repository path.
      #
      # @param provider_full_name [String] exact `owner/repository` identity retained by the connected project
      # @return [ActiveSupport::HashWithIndifferentAccess] provider installation metadata
      # @raise [RepositoryInstallationNotFoundError] when the App is not installed for the repository
      # @raise [RateLimitError] when GitHub explicitly reports exhausted request capacity
      # @raise [ProviderError] when the path, transport, or provider response is invalid
      # @note The request stays on the fixed GitHub API origin, never follows redirects, and never
      #   enumerates installations or repositories outside the single retained identity.
      def repository_installation(provider_full_name)
        owner, repository = repository_path_segments(provider_full_name)
        get(
          "/repos/#{escape_path_segment(owner)}/#{escape_path_segment(repository)}/installation",
          not_found_error: RepositoryInstallationNotFoundError
        )
      rescue ArgumentError, TypeError
        raise ProviderError, 'GitHub App request failed'
      end

      def inspect
        "#<#{self.class.name}>"
      end

      private

      attr_reader :configuration, :jwt_service

      # Fetches App-authenticated JSON and preserves an explicitly meaningful 404.
      #
      # @param path [String] fixed-origin GitHub API path
      # @param not_found_error [Class, nil] sanitized error used when 404 is authoritative
      # @return [ActiveSupport::HashWithIndifferentAccess] parsed provider response
      # @raise [ProviderError] for transport, authentication, rate, or malformed responses
      def get(path, not_found_error: nil)
        response = Import::Clients::HTTP.get(
          "#{API_ROOT}#{path}",
          headers: headers,
          timeout: 30,
          follow_redirects: false
        )

        raise RateLimitError, 'GitHub App request was rate limited' if rate_limited_response?(response)

        if !response.success? && response.code.to_i == 404 && not_found_error
          raise not_found_error, 'GitHub App installation was not found'
        end

        raise ProviderError, 'GitHub App request failed' unless response.success?

        parsed = Gitlab::Json::SafeParser.parse(response.body.to_s)
        raise ProviderError, 'GitHub App response was invalid' unless parsed.is_a?(Hash)

        parsed.with_indifferent_access
      rescue *Gitlab::HTTP::HTTP_ERRORS, JSON::ParserError, ArgumentError
        raise ProviderError, 'GitHub App request failed'
      end

      # Parses a retained repository name into two provider-safe path segments.
      #
      # @param provider_full_name [Object] candidate durable provider identity
      # @return [Array<String>] exact owner and repository segments
      # @raise [ArgumentError] when the identity could alter the endpoint path or is structurally invalid
      def repository_path_segments(provider_full_name)
        segments = provider_full_name.to_s.split('/', -1)
        valid = segments.size == 2 && segments.all? do |segment|
          segment.match?(REPOSITORY_PATH_SEGMENT_PATTERN) && INVALID_REPOSITORY_PATH_SEGMENTS.exclude?(segment)
        end
        return segments if valid

        raise ArgumentError, 'GitHub repository path is invalid'
      end

      # Escapes one already validated path segment before composing the fixed-origin endpoint.
      #
      # @param segment [String] owner or repository name containing only provider-safe characters
      # @return [String] URL-encoded path segment
      # @note Encoding is defense in depth after validation and performs no external I/O.
      def escape_path_segment(segment)
        ERB::Util.url_encode(segment)
      end

      # Distinguishes provider rate limiting without retaining response details.
      # GitHub can report a primary limit as 403 with zero remaining requests,
      # or a primary/secondary limit as 403/429 with Retry-After.
      #
      # @param response [HTTParty::Response] untrusted provider response
      # @return [Boolean] whether the response is an explicit rate limit
      def rate_limited_response?(response)
        status = response.code.to_i
        return true if status == 429
        return false unless status == 403

        headers = response.headers
        headers['Retry-After'].present? || headers['X-RateLimit-Remaining'].to_s == '0'
      rescue NoMethodError, TypeError
        false
      end

      def headers
        {
          'Accept' => 'application/vnd.github+json',
          'Authorization' => "Bearer #{jwt_service.execute}",
          'User-Agent' => "GitLab/#{Gitlab::VERSION}",
          'X-GitHub-Api-Version' => API_VERSION
        }
      end

      def positive_integer(value)
        integer = Integer(value.to_s, 10)
        raise ArgumentError unless integer > 0

        integer
      end
    end
  end
end
