module Gitlab
  module Auth
    Result = Struct.new(:actor, :type) do
      def success?
        actor.present? || type == :ci
      end
    end

    class MissingPersonalTokenError < StandardError; end

    class << self
      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        result =
          ci_request_check(login, password, project) ||
          user_with_password_for_git(login, password) ||
          oauth_access_token_check(login, password) ||
          lfs_token_check(login, password) ||
          personal_access_token_check(login, password)

        rate_limit!(ip, success: result && result.success?, login: login)

        result || Result.new
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

      def ci_request_check(login, password, project)
        Result.new(nil, :ci) if valid_ci_request?(login, password, project)
      end

      def user_with_password_for_git(login, password)
        user = find_with_user_password(login, password)
        raise Gitlab::Auth::MissingPersonalTokenError if user && user.two_factor_enabled?

        Result.new(user, :gitlab_or_ldap) if user
      end

      def oauth_access_token_check(login, password)
        if login == "oauth2" && password.present?
          token = Doorkeeper::AccessToken.by_token(password)
          if token && token.accessible?
            user = User.find_by(id: token.resource_owner_id)
            Result.new(user, :oauth)
          end
        end
      end

      def personal_access_token_check(login, password)
        if login && password
          user = User.find_by_personal_access_token(password)
          validation = User.by_login(login)
          Result.new(user, :personal_token) if user.present? && user == validation
        end
      end

      def lfs_token_check(login, password)
        deploy_key_matches = login.match(/\Alfs\+deploy-key-(\d+)\z/)

        actor =
          if deploy_key_matches
            DeployKey.find(deploy_key_matches[1])
          else
            User.by_login(login)
          end

        if actor
          token_handler = Gitlab::LfsToken.new(actor)

          Result.new(actor, token_handler.type) if Devise.secure_compare(token_handler.value, password)
        end
      end
    end
  end
end
