# frozen_string_literal: true

module Gitlab
  module Sessions
    class CacheStore < ActionDispatch::Session::CacheStore
      DELIMITER = '-'
      ORIGINAL_SESSION_KEY = 'gitlab.original_session_data'
      LAST_WRITE_AT_KEY = '_gitlab_session_last_write_at'
      WRITE_THROTTLE_INTERVAL = 1.hour.to_i

      attr_reader :session_cookie_token_prefix

      def initialize(app, options = {})
        super

        # Use a separate option for expiry so that we only set the Redis TTL in the cache store
        # and not in the session middleware which sets the cookie expiry
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/534096
        @default_options[:redis_expiry] = @cache.options[:expires_in]
        @default_options[:expire_after] = nil
        @session_cookie_token_prefix = options.fetch(:session_cookie_token_prefix, "") || ""
      end

      def find_session(env, sid)
        session_id, session_data = super

        env.set_header(ORIGINAL_SESSION_KEY, [session_id, session_data.deep_dup]) if session_data

        [session_id, session_data]
      end

      def write_session(env, sid, session, options)
        key = cache_key(sid.private_id)

        if !session
          @cache.delete(key)
        elsif session_changed?(env, sid, session) || !write_throttled?(session)
          session[LAST_WRITE_AT_KEY] = Time.now.to_i
          @cache.write(key, session, expires_in: options[:redis_expiry])
        end

        sid
      end

      def generate_sid
        delimiter = session_cookie_token_prefix.empty? ? '' : DELIMITER
        Rack::Session::SessionId.new(session_cookie_token_prefix + delimiter + super.public_id)
      end

      private

      def session_changed?(env, sid, session)
        original_session_id, original_session_data = env.get_header(ORIGINAL_SESSION_KEY)

        original_session_id.nil? || original_session_id != sid ||
          original_session_data.nil? || original_session_data != session
      end

      def write_throttled?(session)
        return false unless Feature.enabled?(:throttle_session_writes, Feature.current_request)

        last_write_at = session[LAST_WRITE_AT_KEY]
        last_write_at && (Time.now.to_i - last_write_at) < WRITE_THROTTLE_INTERVAL
      end

      # ActionDispatch::Session::CacheStore (superclass) prepends
      # hardcoded "_session_id:" to the cache key which doesn't match
      # the previous implementation of Gitlab::Sessions::RedisStore.
      def cache_key(id)
        id
      end
    end
  end
end
