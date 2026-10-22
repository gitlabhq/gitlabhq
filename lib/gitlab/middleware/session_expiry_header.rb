# frozen_string_literal: true

module Gitlab
  module Middleware
    # Reports when the current session expires, so that a page which stays open without
    # reloading can warn the user before its requests quietly start failing.
    #
    # This is middleware rather than a controller hook because the API is mounted
    # alongside Rails and does not share its controllers, yet browser requests to it
    # authenticate through the same session and extend it just as a page load does.
    #
    # Wraps the session middleware, so the session has been committed by the time the
    # header is set and reading it here cannot trigger a write of its own. That ordering
    # (inserted before the session store, so it runs after it on the way out) is also what
    # lets it read the last-write timestamp the store committed on this request; keep it.
    class SessionExpiryHeader
      HEADER = 'X-Gitlab-Session-Expires-At'
      WARDEN_SESSION_KEY = 'warden.user.user.key'

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)

        expires_at = session_expires_at(env)
        headers[HEADER] = expires_at.to_s if expires_at

        [status, headers, body]
      end

      private

      def session_expires_at(env)
        session = env['rack.session']

        return unless session
        # An untouched session means nothing authenticated against it, and loading it
        # here only to find that out would cost a read on every anonymous request.
        return if session.respond_to?(:loaded?) && !session.loaded?
        # Read from the session rather than resolving the user, which costs a query, and
        # leaves token authenticated requests alone since they carry no session.
        return unless session[WARDEN_SESSION_KEY]

        last_write_at = env[::Gitlab::Sessions::CacheStore::COMMITTED_LAST_WRITE_AT_KEY] ||
          session[::Gitlab::Sessions::CacheStore::LAST_WRITE_AT_KEY]
        ::Gitlab::Sessions::Expiry.expires_at(session, last_write_at: last_write_at)
      rescue StandardError => e
        ::Gitlab::ErrorTracking.track_exception(e)
        nil
      end
    end
  end
end
