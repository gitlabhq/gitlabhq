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

      # RequestStore entries
      CURRENT_REQUEST_BYPASS_SESSION_ADMIN_ID_RS_KEY = { res: :current_user_mode, data: :bypass_session_admin_id }.freeze
      CURRENT_REQUEST_ADMIN_MODE_USER_RS_KEY =         { res: :current_user_mode, data: :current_admin }.freeze

      # SessionStore entries
      SESSION_STORE_KEY = :current_user_mode
      ADMIN_MODE_START_TIME_KEY = :admin_mode
      ADMIN_MODE_REQUESTED_TIME_KEY = :admin_mode_requested
      MAX_ADMIN_MODE_TIME = 6.hours
      ADMIN_MODE_REQUESTED_GRACE_PERIOD = 5.minutes

      class << self
        # Admin mode activation requires storing a flag in the user session. Using this
        # method when scheduling jobs in sessionless environments (e.g. Sidekiq, API)
        # will bypass the session check for a user that was already in admin mode
        #
        # If passed a block, it will surround the block execution and reset the session
        # bypass at the end; otherwise you must remember to call '.reset_bypass_session!'
        def bypass_session!(admin_id)
          Gitlab::SafeRequestStore[CURRENT_REQUEST_BYPASS_SESSION_ADMIN_ID_RS_KEY] = admin_id
          # Bypassing the session invalidates the cached value of admin_mode?
          # Any new calls need to be re-computed.
          uncache_admin_mode_state(admin_id)

          Gitlab::AppLogger.debug("Bypassing session in admin mode for: #{admin_id}")

          return unless block_given?

          begin
            yield
          ensure
            reset_bypass_session!(admin_id)
          end
        end

        def reset_bypass_session!(admin_id = nil)
          # Restoring the session bypass invalidates the cached value of admin_mode?
          uncache_admin_mode_state(admin_id)
          Gitlab::SafeRequestStore.delete(CURRENT_REQUEST_BYPASS_SESSION_ADMIN_ID_RS_KEY)
        end

        def bypass_session_admin_id
          Gitlab::SafeRequestStore[CURRENT_REQUEST_BYPASS_SESSION_ADMIN_ID_RS_KEY]
        end

        def uncache_admin_mode_state(admin_id = nil)
          if admin_id
            key = { res: :current_user_mode, user: admin_id, method: :admin_mode? }
            Gitlab::SafeRequestStore.delete(key)
          else
            Gitlab::SafeRequestStore.delete_if do |key|
              key.is_a?(Hash) && key[:res] == :current_user_mode && key[:method] == :admin_mode?
            end
          end
        end

        # Store in the current request the provided user model (only if in admin mode)
        # and yield
        def with_current_admin(admin)
          return yield unless new(admin).admin_mode?

          Gitlab::SafeRequestStore[CURRENT_REQUEST_ADMIN_MODE_USER_RS_KEY] = admin

          Gitlab::AppLogger.debug("Admin mode active for: #{admin.username}")

          yield
        ensure
          Gitlab::SafeRequestStore.delete(CURRENT_REQUEST_ADMIN_MODE_USER_RS_KEY)
        end

        def current_admin
          Gitlab::SafeRequestStore[CURRENT_REQUEST_ADMIN_MODE_USER_RS_KEY]
        end
      end

      def initialize(user)
        @user = user
      end

      def admin_mode?
        return false unless user

        Gitlab::SafeRequestStore.fetch(admin_mode_rs_key) do
          user.admin? && (privileged_runtime? || session_with_admin_mode?)
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

        reset_request_store_cache_entries

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = nil
        current_session_data[ADMIN_MODE_START_TIME_KEY] = Time.now
      end

      def disable_admin_mode!
        return unless user&.admin?

        reset_request_store_cache_entries

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = nil
        current_session_data[ADMIN_MODE_START_TIME_KEY] = nil
      end

      def request_admin_mode!
        return unless user&.admin?

        reset_request_store_cache_entries

        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY] = Time.now
      end

      private

      attr_reader :user

      # RequestStore entry to cache #admin_mode? result
      def admin_mode_rs_key
        @admin_mode_rs_key ||= { res: :current_user_mode, user: user.id, method: :admin_mode? }
      end

      # RequestStore entry to cache #admin_mode_requested? result
      def admin_mode_requested_rs_key
        @admin_mode_requested_rs_key ||= { res: :current_user_mode, user: user.id, method: :admin_mode_requested? }
      end

      def current_session_data
        @current_session ||= Gitlab::NamespacedSessionStore.new(SESSION_STORE_KEY)
      end

      def session_with_admin_mode?
        return true if bypass_session?

        current_session_data.initiated? && current_session_data[ADMIN_MODE_START_TIME_KEY].to_i > MAX_ADMIN_MODE_TIME.ago.to_i
      end

      def admin_mode_requested_in_grace_period?
        current_session_data[ADMIN_MODE_REQUESTED_TIME_KEY].to_i > ADMIN_MODE_REQUESTED_GRACE_PERIOD.ago.to_i
      end

      def bypass_session?
        user&.id && user.id == self.class.bypass_session_admin_id
      end

      def reset_request_store_cache_entries
        Gitlab::SafeRequestStore.delete(admin_mode_rs_key)
        Gitlab::SafeRequestStore.delete(admin_mode_requested_rs_key)
      end

      # Runtimes which imply shell access get admin mode automatically, see Gitlab::Runtime
      def privileged_runtime?
        Gitlab::Runtime.rake? || Gitlab::Runtime.rails_runner? || Gitlab::Runtime.console?
      end
    end
  end
end
