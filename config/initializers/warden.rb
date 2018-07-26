Rails.application.configure do |config|
  Warden::Manager.after_set_user(scope: :user) do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)
  end

  Warden::Manager.before_failure(scope: :user) do |env, opts|
    Gitlab::Auth::BlockedUserTracker.new(env).tap do |tracker|
      tracker.log_blocked_user_activity! if tracker.user_blocked?

      Gitlab::Auth::Activity.new(tracker.user, opts).user_authentication_failed!
    end
  end

  Warden::Manager.after_authentication(scope: :user) do |user, auth, opts|
    ActiveSession.cleanup(user)
    Gitlab::Auth::Activity.new(user, opts).user_authenticated!
  end

  Warden::Manager.after_set_user(scope: :user, only: :fetch) do |user, auth, opts|
    ActiveSession.set(user, auth.request)
  end

  Warden::Manager.after_set_user(scope: :user, only: :set_user) do |user, auth, opts|
    Gitlab::Auth::Activity.new(user, opts).user_session_override!
  end

  Warden::Manager.before_logout(scope: :user) do |user_warden, auth, opts|
    user = user_warden || auth.user

    ActiveSession.destroy(user, auth.request.session.id)
    Gitlab::Auth::Activity.new(user, opts).user_session_destroyed!
  end
end
