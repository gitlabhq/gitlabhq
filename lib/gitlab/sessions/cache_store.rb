# frozen_string_literal: true

module Gitlab
  module Sessions
    class CacheStore < ActionDispatch::Session::CacheStore
      DELIMITER = '-'

      attr_reader :session_cookie_token_prefix

      def initialize(app, options = {})
        super

        @default_options[:redis_expiry] = @cache.options[:expires_in]
        @default_options[:expire_after] = nil
        @session_cookie_token_prefix = options.fetch(:session_cookie_token_prefix, "") || ""
      end

      # Overrides https://github.com/rails/rails/blob/v7.2.2.1/actionpack/lib/action_dispatch/middleware/session/cache_store.rb#L37-L46
      # The only difference is the `expires_in` value is now based on the new option that we set in the intializer above
      def write_session(_env, sid, session, options)
        key = cache_key(sid.private_id)
        if session
          @cache.write(key, session, expires_in: options[:redis_expiry])
        else
          @cache.delete(key)
        end

        sid
      end

      def generate_sid
        delimiter = session_cookie_token_prefix.empty? ? '' : DELIMITER
        Rack::Session::SessionId.new(session_cookie_token_prefix + delimiter + super.public_id)
      end

      private

      # ActionDispatch::Session::CacheStore (superclass) prepends
      # hardcoded "_session_id:" to the cache key which doesn't match
      # the previous implementation of Gitlab::Sessions::RedisStore.
      def cache_key(id)
        id
      end
    end
  end
end
