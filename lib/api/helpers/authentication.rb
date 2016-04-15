module API
  module Helpers
    module Authentication
      PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
      PRIVATE_TOKEN_PARAM = :private_token
      SUDO_HEADER ="HTTP_SUDO"
      SUDO_PARAM = :sudo
      PERSONAL_ACCESS_TOKEN_PARAM = :personal_access_token

      def find_user_by_private_token
        private_token = (params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]).to_s
        User.find_by_authentication_token(private_token)
      end

      def find_user_by_personal_access_token
        personal_access_token = PersonalAccessToken.find_by_token(params[PERSONAL_ACCESS_TOKEN_PARAM])
        if personal_access_token
          personal_access_token.user
        end
      end

      def current_user
        @current_user ||= (find_user_by_private_token || find_user_by_personal_access_token || doorkeeper_guard)

        unless @current_user && Gitlab::UserAccess.allowed?(@current_user)
          return nil
        end

        identifier = sudo_identifier()

        # If the sudo is the current user do nothing
        if identifier && !(@current_user.id == identifier || @current_user.username == identifier)
          render_api_error!('403 Forbidden: Must be admin to use sudo', 403) unless @current_user.is_admin?
          @current_user = User.by_username_or_id(identifier)
          not_found!("No user id or username for: #{identifier}") if @current_user.nil?
        end

        @current_user
      end

      def sudo_identifier()
        identifier ||= params[SUDO_PARAM] || env[SUDO_HEADER]

        # Regex for integers
        if !!(identifier =~ /^[0-9]+$/)
          identifier.to_i
        else
          identifier
        end
      end
    end
  end
end