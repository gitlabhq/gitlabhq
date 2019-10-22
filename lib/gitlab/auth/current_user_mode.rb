# frozen_string_literal: true

module Gitlab
  module Auth
    # Keeps track of the current session user mode
    #
    # In order to perform administrative tasks over some interfaces,
    # an administrator must have explicitly enabled admin-mode
    # e.g. on web access require re-authentication
    class CurrentUserMode
      SESSION_STORE_KEY = :current_user_mode
      ADMIN_MODE_START_TIME_KEY = 'admin_mode'
      MAX_ADMIN_MODE_TIME = 6.hours

      def initialize(user)
        @user = user
      end

      def admin_mode?
        return false unless user

        Gitlab::SafeRequestStore.fetch(request_store_key) do
          user&.admin? && any_session_with_admin_mode?
        end
      end

      def enable_admin_mode!(password: nil, skip_password_validation: false)
        return unless user&.admin?
        return unless skip_password_validation || user&.valid_password?(password)

        current_session_data[ADMIN_MODE_START_TIME_KEY] = Time.now
      end

      def disable_admin_mode!
        current_session_data[ADMIN_MODE_START_TIME_KEY] = nil
        Gitlab::SafeRequestStore.delete(request_store_key)
      end

      private

      attr_reader :user

      def request_store_key
        @request_store_key ||= { res: :current_user_mode, user: user.id }
      end

      def current_session_data
        @current_session ||= Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY)
      end

      def any_session_with_admin_mode?
        return true if current_session_data.initiated? && current_session_data[ADMIN_MODE_START_TIME_KEY].to_i > MAX_ADMIN_MODE_TIME.ago.to_i

        all_sessions.any? do |session|
          session[ADMIN_MODE_START_TIME_KEY].to_i > MAX_ADMIN_MODE_TIME.ago.to_i
        end
      end

      def all_sessions
        @all_sessions ||= ActiveSession.list_sessions(user).lazy.map do |session|
          Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY, session.with_indifferent_access )
        end
      end
    end
  end
end
