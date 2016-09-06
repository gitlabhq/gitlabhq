module Gitlab
  module Auth
    Result = Struct.new(:user, :type)

    class MissingPersonalTokenError < StandardError; end

    class << self
      def find_for_git_client(login, password, project:, ip:)
        raise "Must provide an IP for rate limiting" if ip.nil?

        populate_result(login, password, project, ip)
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

      def populate_result(login, password, project, ip)
        result = Result.new(nil, :ci) if valid_ci_request?(login, password, project)

        result ||=
          user_with_password_for_git(login, password) ||
          oauth_access_token_check(login, password) ||
          lfs_token_check(login, password) ||
          personal_access_token_check(login, password)

        if result && result.type != :ci
          result.type = nil unless result.user

          if result.user && result.type == :gitlab_or_ldap && result.user.two_factor_enabled?
            raise Gitlab::Auth::MissingPersonalTokenError
          end
        end

        success = result ? result.user.present? || [:ci].include?(result.type) : false
        rate_limit!(ip, success: success, login: login)

        result || Result.new
      end

      def user_with_password_for_git(login, password)
        user = find_with_user_password(login, password)
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
          Result.new(user, :personal_token) if user == validation
        end
      end

      def lfs_token_check(login, password)
        actor =
          if login =~ /\Alfs-deploy-key-\d+\Z/
            /\d+\Z/.match(login) do |id|
              DeployKey.find(id[0])
            end
          else
            User.by_login(login)
          end

        token_handler = Gitlab::LfsToken.new(actor)

        Result.new(actor, token_handler.type) if actor && Devise.secure_compare(token_handler.value, password)
      end
    end
  end
end
