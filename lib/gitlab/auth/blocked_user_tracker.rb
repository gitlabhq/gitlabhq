# frozen_string_literal: true
module Gitlab
  module Auth
    class BlockedUserTracker
      ACTIVE_RECORD_REQUEST_PARAMS = 'action_dispatch.request.request_parameters'

      def self.log_if_user_blocked(env)
        message = env.dig('warden.options', :message)

        # Devise calls User#active_for_authentication? on the User model and then
        # throws an exception to Warden with User#inactive_message:
        # https://github.com/plataformatec/devise/blob/v4.2.1/lib/devise/hooks/activatable.rb#L8
        #
        # Since Warden doesn't pass the user record to the failure handler, we
        # need to do a database lookup with the username. We can limit the
        # lookups to happen when the user was blocked by checking the inactive
        # message passed along by Warden.
        return unless message == User::BLOCKED_MESSAGE

        login = env.dig(ACTIVE_RECORD_REQUEST_PARAMS, 'user', 'login')

        return unless login.present?

        user = User.by_login(login)

        return unless user&.blocked?

        Gitlab::AppLogger.info("Failed login for blocked user: user=#{user.username} ip=#{env['REMOTE_ADDR']}")
        SystemHooksService.new.execute_hooks_for(user, :failed_login)

        true
      rescue TypeError
      end
    end
  end
end
