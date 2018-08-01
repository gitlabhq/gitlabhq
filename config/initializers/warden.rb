Rails.application.configure do |config|
  Warden::Manager.after_set_user(scope: :user) do |user, auth, opts|
    Gitlab::Auth::UniqueIpsLimiter.limit_user!(user)

    activity = Gitlab::Auth::Activity.new(opts)

    case opts[:event]
    when :authentication
      activity.user_authenticated!
    when :set_user
      activity.user_authenticated!
      activity.user_session_override!
    when :fetch # rubocop:disable Lint/EmptyWhen
      # We ignore session fetch events
    else
      activity.user_session_override!
    end
  end

  Warden::Manager.after_authentication(scope: :user) do |user, auth, opts|
    ActiveSession.cleanup(user)
  end

  Warden::Manager.after_set_user(scope: :user, only: :fetch) do |user, auth, opts|
    ActiveSession.set(user, auth.request)
  end

  Warden::Manager.before_failure(scope: :user) do |env, opts|
    Gitlab::Auth::Activity.new(opts).user_authentication_failed!
  end

  Warden::Manager.before_logout(scope: :user) do |user, auth, opts|
    user ||= auth.user

    if user.blocked?
      Gitlab::Auth::Activity.new(opts).user_blocked!
      Gitlab::Auth::BlockedUserTracker.new(user, auth).log_blocked_user_activity!
    end

    Gitlab::Auth::Activity.new(opts).user_session_destroyed!
    ActiveSession.destroy(user, auth.request.session.id)
  end
end
