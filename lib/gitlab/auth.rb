module Gitlab
  class Auth
    Result = Struct.new(:user, :type)

    class << self
      def find(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        result = Result.new

        if valid_ci_request?(login, password, project)
          result.type = :ci
        elsif result.user = find_in_gitlab_or_ldap(login, password)
          result.type = :gitlab_or_ldap
        elsif result.user = oauth_access_token_check(login, password)
          result.type = :oauth
        end

        rate_limit!(ip, success: !!result.user || (result.type == :ci), login: login)
        result
      end

      def find_in_gitlab_or_ldap(login, password)
        user = User.by_login(login)

        # If no user is found, or it's an LDAP server, try LDAP.
        #   LDAP users are only authenticated via LDAP
        if user.nil? || user.ldap_user?
          # Second chance - try LDAP authentication
          return nil unless Gitlab::LDAP::Config.enabled?

          Gitlab::LDAP::Authentication.login(login, password)
        else
          user if user.valid_password?(password)
        end
      end

      private

      def valid_ci_request?(login, password, project)
        matched_login = /(?<service>^[a-zA-Z]*-ci)-token$/.match(login)

        return false unless project && matched_login.present?

        underscored_service = matched_login['service'].underscore

        if underscored_service == 'gitlab_ci'
          project && project.valid_build_token?(password)
        elsif Service.available_services_names.include?(underscored_service)
          # We treat underscored_service as a trusted input because it is included
          # in the Service.available_services_names whitelist.
          service_method = "#{underscored_service}_service"
          service = project.send(service_method)

          service && service.activated? && service.valid_token?(password)
        end
      end

      def oauth_access_token_check(login, password)
        if login == "oauth2" && password.present?
          token = Doorkeeper::AccessToken.by_token(password)
          token && token.accessible? && User.find_by(id: token.resource_owner_id)
        end
      end

      def rate_limit!(ip, success:, login:)
        # If the user authenticated successfully, we reset the auth failure count
        # from Rack::Attack for that IP. A client may attempt to authenticate
        # with a username and blank password first, and only after it receives
        # a 401 error does it present a password. Resetting the count prevents
        # false positives.
        #
        # Otherwise, we let Rack::Attack know there was a failed authentication
        # attempt from this IP. This information is stored in the Rails cache
        # (Redis) and will be used by the Rack::Attack middleware to decide
        # whether to block requests from this IP.

        config = Gitlab.config.rack_attack.git_basic_auth
        return unless config.enabled

        if success
          Rack::Attack::Allow2Ban.reset(ip, config)
        else
          banned = Rack::Attack::Allow2Ban.filter(ip, config) do
            if config.ip_whitelist.include?(ip)
              # Don't increment the ban counter for this IP
              false
            else
              # Increment the ban counter for this IP
              true
            end
          end

          if banned
            Rails.logger.info "IP #{ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
          end
        end
      end
    end
  end
end
