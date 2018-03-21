Rails.application.configure do |config|
  Warden::Manager.after_set_user do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)
  end

  Warden::Manager.before_failure do |env, opts|
    Gitlab::Auth::BlockedUserTracker.log_if_user_blocked(env)
  end
end
