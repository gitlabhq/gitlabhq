# frozen_string_literal: true

module Gitlab
  module Redis
    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'

      class << self
        # Full list of options:
        # https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-c-new
        def active_support_config
          {
            redis: pool,
            compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
            namespace: CACHE_NAMESPACE,
            expires_in: default_ttl_seconds
          }
        end

        def default_ttl_seconds
          ENV.fetch('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS', 8.hours).to_i
        end

        # Exposes redis for Peek adapter. To be removed after ClusterCache migration.
        def multistore_redis
          redis
        end

        private

        def redis
          primary_store = ::Redis.new(Gitlab::Redis::ClusterCache.params)
          secondary_store = ::Redis.new(params)

          MultiStore.new(primary_store, secondary_store, store_name)
        end
      end
    end
  end
end
