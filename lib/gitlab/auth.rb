module Gitlab
  module Auth
    Result = Struct.new(:user, :type)

    class << self
      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        result = Result.new

        if valid_ci_request?(login, password, project)
          result.type = :ci
        elsif result.user = find_with_user_password(login, password)
          if result.user.two_factor_enabled?
            result.user = nil
            result.type = :missing_personal_token
          else
            result.type = :gitlab_or_ldap
          end
        elsif result.user = oauth_access_token_check(login, password)
          result.type = :oauth
        elsif result.user = personal_access_token_check(login, password)
          result.type = :personal_token
        end

        success = result.user.present? || [:ci, :missing_personal_token].include?(result.type)
        rate_limit!(ip, success: success, login: login)
        result
      end

      def find_with_user_password(login, password)
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

      def rate_limit!(ip, success:, login:)
        rate_limiter = Gitlab::Auth::IpRateLimiter.new(ip)
        return unless rate_limiter.enabled?

        if success
          # Repeated login 'failures' are normal behavior for some Git clients so
          # it is important to reset the ban counter once the client has proven
          # they are not a 'bad guy'.
          rate_limiter.reset!
        else
          # Register a login failure so that Rack::Attack can block the next
          # request from this IP if needed.
          rate_limiter.register_fail!

          if rate_limiter.banned?
            Rails.logger.info "IP #{ip} failed to login " \
              "as #{login} but has been temporarily banned from Git auth"
          end
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
          service = project.public_send("#{underscored_service}_service")

          service && service.activated? && service.valid_token?(password)
        end
      end

      def oauth_access_token_check(login, password)
        if login == "oauth2" && password.present?
          token = Doorkeeper::AccessToken.by_token(password)
          token && token.accessible? && User.find_by(id: token.resource_owner_id)
        end
      end

      def personal_access_token_check(login, password)
        if login && password
          user = User.find_by_personal_access_token(password)
          user if user && user.username == login
        end
      end
    end
  end
end
