# frozen_string_literal: true

module Gitlab
  module Auth
    # Keeps track of the current session user mode
    #
    # In order to perform administrative tasks over some interfaces,
    # an administrator must have explicitly enabled admin-mode
    # e.g. on web access require re-authentication
    class CurrentUserMode
      NotRequestedError = Class.new(StandardError)

      SESSION_STORE_KEY = :current_user_mode
      ADMIN_MODE_START_TIME_KEY = 'admin_mode'
      ADMIN_MODE_REQUESTED_TIME_KEY = 'admin_mode_requested'
      MAX_ADMIN_MODE_TIME = 6.hours
      ADMIN_MODE_REQUESTED_GRACE_PERIOD = 5.minutes

      def initialize(user)
        @user = user
      end

      def admin_mode?
        return false unless user

        Gitlab::SafeRequestStore.fetch(admin_mode_rs_key) do
          user.admin? && any_session_with_admin_mode?
        end
      end

      def admin_mode_requested?
        return false unless user

        Gitlab::SafeRequestStore.fetch(admin_mode_requested_rs_key) do
          user.admin? && admin_mode_requested_in_grace_period?
        end
      end

      def enable_admin_mode!(password: nil, skip_password_validation: false)
        return unless user&.admin?
        return unless skip_password_validation || user&.valid_password?(password)

        raise NotRequestedError unless admin_mode_requested?

        reset_request_store

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = nil
        current_session_data[ADMIN_MODE_START_TIME_KEY] = Time.now
      end

      def enable_sessionless_admin_mode!
        request_admin_mode! && enable_admin_mode!(skip_password_validation: true)
      end

      def disable_admin_mode!
        return unless user&.admin?

        reset_request_store

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = nil
        current_session_data[ADMIN_MODE_START_TIME_KEY] = nil
      end

      def request_admin_mode!
        return unless user&.admin?

        reset_request_store

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = Time.now
      end

      private

      attr_reader :user

      def admin_mode_rs_key
        @admin_mode_rs_key ||= { res: :current_user_mode, user: user.id, method: :admin_mode? }
      end

      def admin_mode_requested_rs_key
        @admin_mode_requested_rs_key ||= { res: :current_user_mode, user: user.id, method: :admin_mode_requested? }
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

      def admin_mode_requested_in_grace_period?
        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY].to_i > ADMIN_MODE_REQUESTED_GRACE_PERIOD.ago.to_i
      end

      def reset_request_store
        Gitlab::SafeRequestStore.delete(admin_mode_rs_key)
        Gitlab::SafeRequestStore.delete(admin_mode_requested_rs_key)
      end
    end
  end
end
