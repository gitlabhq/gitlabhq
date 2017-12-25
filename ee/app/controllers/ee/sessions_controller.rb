module EE
  module SessionsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :gitlab_geo_login, only: [:new]
      before_action :gitlab_geo_logout, only: [:destroy]
    end

    private

    def gitlab_geo_login
      return unless ::Gitlab::Geo.secondary?
      return if signed_in?

      oauth = ::Gitlab::Geo::OauthSession.new

      # share full url with primary node by oauth state
      user_return_to = URI.join(root_url, session[:user_return_to].to_s).to_s
      oauth.return_to = stored_redirect_uri || user_return_to

      redirect_to oauth_geo_auth_url(state: oauth.generate_oauth_state)
    end

    def gitlab_geo_logout
      return unless ::Gitlab::Geo.secondary?

      oauth = ::Gitlab::Geo::OauthSession.new(access_token: session[:access_token])
      @geo_logout_state = oauth.generate_logout_state # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def log_failed_login
      ::AuditEventService.new(request.filtered_parameters['user']['login'], nil, ip_address: request.remote_ip)
          .for_failed_login.unauth_security_event

      super
    end

    override :redirect_allowed_to?
    def redirect_allowed_to?(uri)
      # Redirect is not only allowed to current host, but also to other Geo
      # nodes. relative_url_root *must* be ignored here as we don't know what
      # is root and what is path
      super || begin
        truncated = uri.dup.tap { |uri| uri.path = '/' }

        ::GeoNode.with_url_prefix(truncated).exists?
      end
    end
  end
end
