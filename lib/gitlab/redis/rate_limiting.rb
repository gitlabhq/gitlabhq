# frozen_string_literal: true

module Gitlab
  module Redis
    class RateLimiting < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on RateLimiting used to be stored on Cache.
        def config_fallback
          Cache
        end

        def cache_store
          @cache_store ||= ActiveSupport::Cache::RedisCacheStore.new(redis: pool, namespace: Cache::CACHE_NAMESPACE)
        end

        private

        def redis
          primary_store = ::Redis.new(::Gitlab::Redis::ClusterRateLimiting.params)
          secondary_store = ::Redis.new(params)

          MultiStore.new(primary_store, secondary_store, name.demodulize)
        end
      end
    end
  end
end
