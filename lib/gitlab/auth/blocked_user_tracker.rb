# frozen_string_literal: true
module Gitlab
  module Auth
    class BlockedUserTracker
      include Gitlab::Utils::StrongMemoize

      ACTIVE_RECORD_REQUEST_PARAMS = 'action_dispatch.request.request_parameters'

      def initialize(env)
        @env = env
      end

      def user_blocked?
        user&.blocked?
      end

      def user
        return unless has_user_blocked_message?

        strong_memoize(:user) do
          # Check for either LDAP or regular GitLab account logins
          login = @env.dig(ACTIVE_RECORD_REQUEST_PARAMS, 'username') ||
            @env.dig(ACTIVE_RECORD_REQUEST_PARAMS, 'user', 'login')

          User.by_login(login) if login.present?
        end
      rescue TypeError
      end

      def log_blocked_user_activity!
        return unless user_blocked?

        Gitlab::AppLogger.info("Failed login for blocked user: user=#{user.username} ip=#{@env['REMOTE_ADDR']}")
        SystemHooksService.new.execute_hooks_for(user, :failed_login)
        true
      rescue TypeError
      end

      private

      ##
      # Devise calls User#active_for_authentication? on the User model and then
      # throws an exception to Warden with User#inactive_message:
      # https://github.com/plataformatec/devise/blob/v4.2.1/lib/devise/hooks/activatable.rb#L8
      #
      # Since Warden doesn't pass the user record to the failure handler, we
      # need to do a database lookup with the username. We can limit the
      # lookups to happen when the user was blocked by checking the inactive
      # message passed along by Warden.
      #
      def has_user_blocked_message?
        strong_memoize(:user_blocked_message) do
          message = @env.dig('warden.options', :message)
          message == User::BLOCKED_MESSAGE
        end
      end
    end
  end
end
