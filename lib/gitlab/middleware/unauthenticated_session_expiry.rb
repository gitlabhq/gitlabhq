# frozen_string_literal: true

module Gitlab
  module Middleware
    # By default, all sessions are given the same expiration time configured in
    # the session store (e.g. 1 week). However, unauthenticated users can
    # generate a lot of sessions, primarily for CSRF verification. It makes
    # sense to reduce the TTL for unauthenticated to something much lower than
    # the default (e.g. 2 hours) to limit Redis memory. In addition, Rails
    # creates a new session after login, so the short TTL doesn't even need to
    # be extended.
    class UnauthenticatedSessionExpiry
      def initialize(app)
        @app = app
      end

      def call(env)
        result = @app.call(env)

        warden = env['warden']
        user = catch(:warden) { warden && warden.user } # rubocop:disable Cop/BanCatchThrow -- ignore Warden errors since we're outside Warden::Manager

        unless user
          # This option is used by Gitlab::Sessions::CacheStore when it persists the session to Redis
          env['rack.session.options'][:redis_expiry] = Settings.gitlab['unauthenticated_session_expire_delay']
        end

        result
      end
    end
  end
end
