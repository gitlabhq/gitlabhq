# frozen_string_literal: true

module SessionsHelper
  include Gitlab::Utils::StrongMemoize

  def recently_confirmed_com?
    strong_memoize(:recently_confirmed_com) do
      ::Gitlab.com? &&
        !!flash[:notice]&.include?(t(:confirmed, scope: [:devise, :confirmations]))
    end
  end

  def unconfirmed_email?
    flash[:alert] == t(:unconfirmed, scope: [:devise, :failure])
  end

  # By default, all sessions are given the same expiration time configured in
  # the session store (e.g. 1 week). However, unauthenticated users can
  # generate a lot of sessions, primarily for CSRF verification. It makes
  # sense to reduce the TTL for unauthenticated to something much lower than
  # the default (e.g. 1 hour) to limit Redis memory. In addition, Rails
  # creates a new session after login, so the short TTL doesn't even need to
  # be extended.
  def limit_session_time
    set_session_time(Settings.gitlab['unauthenticated_session_expire_delay'])
  end

  def ensure_authenticated_session_time
    set_session_time(nil)
  end

  def set_session_time(expiry_s)
    # Rack sets this header, but not all tests may have it: https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L251-L259
    return unless request.env['rack.session.options']

    # This works because Rack uses these options every time a request is handled, and redis-store
    # uses the Rack setting first:
    # 1. https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L342
    # 2. https://github.com/redis-store/redis-store/blob/3acfa95f4eb6260c714fdb00a3d84be8eedc13b2/lib/redis/store/ttl.rb#L32
    request.env['rack.session.options'][:expire_after] = expiry_s
  end

  def send_rate_limited?(user)
    Gitlab::ApplicationRateLimiter.peek(:email_verification_code_send, scope: user)
  end

  def obfuscated_email(email)
    # Moved to Gitlab::Utils::Email in 15.9
    Gitlab::Utils::Email.obfuscated_email(email)
  end

  def remember_me_enabled?
    Gitlab::CurrentSettings.remember_me_enabled?
  end
end
