# frozen_string_literal: true

module Import
  class ValidateRemoteGitEndpointService
    attr_reader :uri, :user, :password

    def initialize(params)
      @params = params

      # Special characters (#, ?, /) in the password would otherwise cause
      # Addressable::URI.parse to misparse the URL.
      sanitizer = Gitlab::UrlSanitizer.new(@params[:url])
      @uri = Gitlab::Utils.parse_url(sanitizer.sanitized_url)
      @user = @params[:user].presence || sanitizer.credentials[:user]
      @password = @params[:password].presence || sanitizer.credentials[:password]
    rescue Addressable::URI::InvalidURIError
      # Fall back to simple parsing for truly malformed URLs so that
      # #execute can return a proper error response instead of raising.
      @uri = Gitlab::Utils.parse_url(@params[:url])
      @user = @params[:user].presence
      @password = @params[:password].presence
    end

    def execute
      if uri && uri.hostname && Project::VALID_IMPORT_PROTOCOLS.include?(uri.scheme)
        # Inject auth credentials first so that validate_url_security!
        # validates the final URL that will be sent to Gitaly.
        ensure_auth_credentials!
        validate_url_security!

        return ServiceResponse.success if Gitlab::GitalyClient::RemoteService.exists?(uri.to_s) # rubocop: disable CodeReuse/ActiveRecord -- false positive
      end

      failure_response
    rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
      ServiceResponse.error(
        message: e.message.gsub(uri.to_s, Gitlab::UrlSanitizer.new(uri.to_s).masked_url),
        reason: 400
      )
    rescue GRPC::BadStatus
      # There are a several subclasses of GRPC::BadStatus, but in our case the
      # scenario we're interested in the presence of a valid, accessible
      # repository, so this treats them all as equivalent.
      failure_response
    end

    private

    def failure_response
      ServiceResponse.error(
        message: 'Unable to access repository with the URL and credentials provided',
        reason: 400
      )
    end

    def validate_url_security!
      Gitlab::HTTP_V2::UrlBlocker.validate!(
        uri.to_s,
        **Import::Framework::UrlBlockerParams.new.to_h.merge(
          schemes: Project::VALID_IMPORT_PROTOCOLS,
          ports: Project::VALID_IMPORT_PORTS,
          dns_rebind_protection: dns_rebind_protection?
        )
      )
    end

    def dns_rebind_protection?
      return false if Gitlab.http_proxy_env?

      Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
    end

    def ensure_auth_credentials!
      return unless user && password

      original_hostname = uri.hostname

      uri.user = Gitlab::UrlSanitizer.encode_percent(user)
      uri.password = Gitlab::UrlSanitizer.encode_percent(password)

      return if uri.hostname == original_hostname

      raise Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError, uri.to_s
    end
  end
end
