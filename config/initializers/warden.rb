Rails.application.configure do |config|
  Warden::Manager.after_set_user(scope: :user) do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)
  end

  Warden::Manager.before_failure(scope: :user) do |env, opts|
    Gitlab::Auth::BlockedUserTracker.log_if_user_blocked(env)
  end

  Warden::Manager.after_authentication(scope: :user) do |user, auth, opts|
    ActiveSession.cleanup(user)
  end

  Warden::Manager.after_set_user(scope: :user, only: :fetch) do |user, auth, opts|
    ActiveSession.set(user, auth.request)
  end

  Warden::Manager.before_logout(scope: :user) do |user, auth, opts|
    ActiveSession.destroy(user || auth.user, auth.request.session.id)
  end
end
