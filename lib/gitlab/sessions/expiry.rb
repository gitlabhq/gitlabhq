# frozen_string_literal: true

module Gitlab
  module Sessions
    # When the current session expires, for both session expiry settings: a fixed
    # deadline measured from sign-in, or a sliding one measured from last activity.
    #
    # The sliding deadline is reported only where SAML is configured. There an expired
    # session sends the user out to the identity provider, so the page they left open
    # cannot recover on its own and gives no sign of what happened.
    class Expiry
      class << self
        # last_write_at: the session's activity timestamp as of the end of this request; see
        # CacheStore::COMMITTED_LAST_WRITE_AT_KEY for why the caller passes it in.
        def expires_at(session, last_write_at:)
          return expires_from_init_at(session) if Gitlab::Auth::SessionExpireFromInitEnforcer.enabled?
          return unless activity_expiry_reported?

          expires_from_activity_at(last_write_at)
        end

        private

        # Gated per instance rather than per user: the middleware reporting this has no
        # actor to hand, and a per-user gate there would disagree with the one deciding
        # whether the modal renders.
        def activity_expiry_reported?
          Gitlab::Auth::Saml::Config.enabled? &&
            Feature.enabled?(:session_expire_modal_on_saml_instances, :instance)
        end

        def expires_from_activity_at(last_write_at)
          last_write_at.to_i + session_lifetime if last_write_at
        end

        # Reads the live setting through the enforcer, so the reported deadline matches what
        # signs the user out.
        def expires_from_init_at(session)
          expires_at = Gitlab::Auth::SessionExpireFromInitEnforcer.session_expires_at(session)

          expires_at if expires_at.to_i > 0
        end

        # The boot-cached delay the Redis session TTL is built from (not the live setting),
        # so the reported deadline matches the real expiry even before a settings change
        # takes effect on restart.
        def session_lifetime
          Settings.gitlab['session_expire_delay'] * 60
        end
      end
    end
  end
end
