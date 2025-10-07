# frozen_string_literal: true

# code inspired by Devise Timeoutable
# https://github.com/heartcombo/devise/blob/fec67f98f26fcd9a79072e4581b1bd40d0c7fa1d/lib/devise/hooks/timeoutable.rb#L8
module Gitlab
  module Auth
    class SessionExpireFromInitEnforcer
      SESSION_NAMESPACE = :sefie

      attr_reader :warden, :opts

      def self.session_expires_at(controller_session = Session.current)
        warden_session = controller_session['warden.user.user.session']
        session = Gitlab::NamespacedSessionStore.new(SESSION_NAMESPACE, warden_session)
        signed_in_at = session['signed_in_at']
        return 0 unless signed_in_at.present?

        signed_in_at + timeout_value
      end

      def self.enabled?
        Gitlab::CurrentSettings.session_expire_from_init
      end

      def self.timeout_value
        Gitlab::CurrentSettings.session_expire_delay * 60
      end

      def initialize(warden, opts)
        @warden = warden
        @opts = opts
      end

      def enabled?
        self.class.enabled? && opts[:store] != false
      end

      def set_login_time
        return unless enabled?

        set_signed_in_at
      end

      def enforce!
        return unless enabled?

        signed_in_at = session['signed_in_at']

        # immediately after the setting is enabled, users may not have this value set
        # we set it here so users don't have to log out and log back in to set the expiry
        unless signed_in_at.present?
          set_signed_in_at
          return
        end

        time_since_sign_in = Time.current.utc.to_i - signed_in_at

        return unless time_since_sign_in > timeout_value

        ::Devise.sign_out_all_scopes ? proxy.sign_out : proxy.sign_out(scope)
        throw :warden, scope: scope, message: :timeout # rubocop:disable Cop/BanCatchThrow -- this is called from a Warden hook, which depends on throw :warden to halt and redirect
      end

      private

      def set_signed_in_at
        session['signed_in_at'] = Time.current.utc.to_i
      end

      def timeout_value
        self.class.timeout_value
      end

      def proxy
        @proxy ||= ::Devise::Hooks::Proxy.new(warden)
      end

      def scope
        opts[:scope]
      end

      def session
        return @session if @session

        session = warden.session(scope)
        @session = Gitlab::NamespacedSessionStore.new(SESSION_NAMESPACE, session)
      end
    end
  end
end
