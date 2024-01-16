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
          # This works because Rack uses these options every time a request is handled, and redis-store
          # uses the Rack setting first:
          # 1. https://github.com/rack/rack/blob/fdcd03a3c5a1c51d1f96fc97f9dfa1a9deac0c77/lib/rack/session/abstract/id.rb#L342
          # 2. https://github.com/redis-store/redis-store/blob/3acfa95f4eb6260c714fdb00a3d84be8eedc13b2/lib/redis/store/ttl.rb#L32
          env['rack.session.options'][:expire_after] = Settings.gitlab['unauthenticated_session_expire_delay']
        end

        result
      end
    end
  end
end
