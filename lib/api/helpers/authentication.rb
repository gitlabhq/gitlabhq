module API
  module Helpers
    module Authentication
      PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
      PRIVATE_TOKEN_PARAM = :private_token
      SUDO_HEADER ="HTTP_SUDO"
      SUDO_PARAM = :sudo

      def current_user
        private_token = (params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]).to_s
        @current_user ||= (User.find_by(authentication_token: private_token) || doorkeeper_guard)

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