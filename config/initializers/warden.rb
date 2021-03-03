# frozen_string_literal: true

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
    Gitlab::AnonymousSession.new(auth.request.remote_ip).cleanup_session_per_ip_count
  end

  Warden::Manager.after_set_user(scope: :user, only: :fetch) do |user, auth, opts|
    ActiveSession.set(user, auth.request)
  end

  Warden::Manager.before_failure(scope: :user) do |env, opts|
    Gitlab::Auth::Activity.new(opts).user_authentication_failed!
  end

  Warden::Manager.before_logout(scope: :user) do |user, auth, opts|
    user ||= auth.user

    # Rails CSRF protection may attempt to log out a user before that
    # user even logs in
    next unless user

    activity = Gitlab::Auth::Activity.new(opts)
    tracker = Gitlab::Auth::BlockedUserTracker.new(user, auth)

    ActiveSession.destroy_session(user, auth.request.session.id.private_id) if auth.request.session.id
    activity.user_session_destroyed!

    ##
    # It is possible that `before_logout` event is going to be triggered
    # multiple times during the request lifecycle. We want to increment
    # metrics and write logs only once in that case.
    #
    # 'warden.auth.*' is our custom hash key that follows usual convention
    # of naming keys in the Rack env hash.
    #
    next if auth.env['warden.auth.user.blocked']

    if user.blocked?
      activity.user_blocked!
      tracker.log_activity!
    end

    auth.env['warden.auth.user.blocked'] = true
  end
end
