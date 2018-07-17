Rails.application.configure do |config|
  Warden::Manager.after_set_user(scope: :user) do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)
  end

  Warden::Manager.before_failure(scope: :user) do |env, opts|
    Gitlab::Auth::BlockedUserTracker.log_if_user_blocked(env)

    Gitlab::Auth::Activity.new(opts).user_authentication_failed!
  end

  Warden::Manager.after_authentication(scope: :user) do |user, auth, opts|
    ActiveSession.cleanup(user)

    Gitlab::Auth::Activity.new(opts).user_authenticated!
  end

  Warden::Manager.after_set_user(scope: :user, only: :fetch) do |user, auth, opts|
    ActiveSession.set(user, auth.request)

    Gitlab::Auth::Activity.new(opts).user_session_fetched!
  end

  Warden::Manager.after_set_user(scope: :user, only: :set_user) do |user, auth, opts|
    Gitlab::Auth::Activity.new(opts).user_set_manually!
  end

  Warden::Manager.before_logout(scope: :user) do |user, auth, opts|
    ActiveSession.destroy(user || auth.user, auth.request.session.id)

    Gitlab::Auth::Activity.new(opts).user_logout!
  end
end
