# frozen_string_literal: true

module Gitlab
  module Redis
    class FeatureFlag < ::Gitlab::Redis::Wrapper
      FeatureFlagStore = Class.new(ActiveSupport::Cache::RedisCacheStore)

      class << self
        # The data we store on FeatureFlag is currently stored on Cache.
        def config_fallback
          Cache
        end

        def cache_store
          @cache_store ||= FeatureFlagStore.new(
            redis: pool,
            pool: false,
            compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
            namespace: Cache::CACHE_NAMESPACE,
            expires_in: 1.hour
          )
        end
      end
    end
  end
end
