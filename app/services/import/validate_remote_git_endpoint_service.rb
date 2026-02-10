# frozen_string_literal: true

module Import
  class ValidateRemoteGitEndpointService
    attr_reader :uri, :user, :password

    def initialize(params)
      @params = params
      @uri = Gitlab::Utils.parse_url(@params[:url])
      @user = @params[:user].presence
      @password = @params[:password].presence
    end

    def execute
      if uri && uri.hostname && Project::VALID_IMPORT_PROTOCOLS.include?(uri.scheme)
        # Validate URL against security policies before attempting connection
        validate_url_security!
        ensure_auth_credentials!

        return ServiceResponse.success if Gitlab::GitalyClient::RemoteService.exists?(uri.to_s) # rubocop: disable CodeReuse/ActiveRecord -- false positive
      end

      failure_response
    rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
      ServiceResponse.error(
        message: e.message.gsub(uri, Gitlab::UrlSanitizer.new(uri).masked_url),
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
        schemes: Project::VALID_IMPORT_PROTOCOLS,
        ports: Project::VALID_IMPORT_PORTS,
        allow_localhost: allow_local_requests?,
        allow_local_network: allow_local_requests?,
        dns_rebind_protection: dns_rebind_protection?,
        deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
        outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
      )
    end

    def allow_local_requests?
      Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def dns_rebind_protection?
      return false if Gitlab.http_proxy_env?

      Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
    end

    def ensure_auth_credentials!
      return unless user && password

      uri.user = user
      uri.password = password
    end
  end
end
