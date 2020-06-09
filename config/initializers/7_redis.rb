# Use caching across all environments
# Full list of options:
# https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-c-new
caching_config_hash = {}
caching_config_hash[:redis] = Gitlab::Redis::Cache.pool
caching_config_hash[:compress] = Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1'))
caching_config_hash[:namespace] = Gitlab::Redis::Cache::CACHE_NAMESPACE
caching_config_hash[:expires_in] = 2.weeks # Cache should not grow forever

Gitlab::Application.config.cache_store = :redis_cache_store, caching_config_hash

# Make sure we initialize a Redis connection pool before multi-threaded
# execution starts by
# 1. Sidekiq
# 2. Rails.cache
# 3. HTTP clients
Gitlab::Redis::Cache.with { nil }
Gitlab::Redis::Queues.with { nil }
Gitlab::Redis::SharedState.with { nil }
