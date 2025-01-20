# frozen_string_literal: true

module Gitlab
  module Sessions
    class StoreBuilder
      attr_reader :cookie_key, :session_cookie_token_prefix

      def initialize(cookie_key, session_cookie_token_prefix)
        @cookie_key = cookie_key
        @session_cookie_token_prefix = session_cookie_token_prefix
      end

      def prepare
        if Gitlab::Utils.to_boolean(ENV.fetch('USE_REDIS_CACHE_STORE_AS_SESSION_STORE', 'false'))
          # Set expiry to very large number (practically permanent) instead of the default 1 week
          # as some specs rely on time travel to a distant past or future.
          Settings.gitlab['session_expire_delay'] = ::Gitlab::Database::MAX_INT_VALUE if Rails.env.test?

          [
            ::Gitlab::Sessions::CacheStore, # Using the cookie_store would enable session replay attacks
            {
              cache: ActiveSupport::Cache::RedisCacheStore.new(
                namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
                redis: Gitlab::Redis::Sessions,
                expires_in: Settings.gitlab['session_expire_delay'] * 60,
                coder: Gitlab::Sessions::CacheStoreCoder
              ),
              key: cookie_key,
              secure: Gitlab.config.gitlab.https,
              httponly: true,
              path: Rails.application.config.relative_url_root.presence || '/',
              session_cookie_token_prefix: session_cookie_token_prefix
            }
          ]
        else
          [
            Gitlab::Sessions::RedisStore, # Using the cookie_store would enable session replay attacks
            {
              redis_server: Gitlab::Redis::Sessions.params.merge(
                namespace: Gitlab::Redis::Sessions::SESSION_NAMESPACE,
                serializer: Gitlab::Sessions::RedisStoreSerializer
              ),
              key: cookie_key,
              secure: Gitlab.config.gitlab.https,
              httponly: true,
              expires_in: Settings.gitlab['session_expire_delay'] * 60,
              path: Rails.application.config.relative_url_root.presence || '/',
              session_cookie_token_prefix: session_cookie_token_prefix
            }
          ]
        end
      end
    end
  end
end
