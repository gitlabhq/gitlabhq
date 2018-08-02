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
    ActiveSession.destroy(user || auth.user, auth.request.session.id)

    activity = Gitlab::Auth::Activity.new(opts)
    tracker = Gitlab::Auth::BlockedUserTracker.new(user, auth)

    ##
    # It is possible that `before_logout` event is going to be triggered
    # multiple times during the request lifecycle. We want to increment
    # metrics and write logs only once in that case.
    #
    next if (auth.env['warden.auth.trackers'] ||= {}).push(activity).many?

    if user.blocked?
      activity.user_blocked!
      tracker.log_activity!
    end

    activity.user_session_destroyed!
  end
end
