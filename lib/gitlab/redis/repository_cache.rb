# frozen_string_literal: true

module Gitlab
  module Redis
    class RepositoryCache < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on RepositoryCache used to be stored on Cache.
        def config_fallback
          Cache
        end

        def cache_store
          @cache_store ||= ActiveSupport::Cache::RedisCacheStore.new(
            redis: pool,
            compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
            namespace: Cache::CACHE_NAMESPACE,
            expires_in: Cache.default_ttl_seconds
          )
        end
      end
    end
  end
end
