# frozen_string_literal: true

module ProtectedBranches
  class CacheService < ProtectedBranches::BaseService
    CACHE_ROOT_KEY = 'cache:gitlab:protected_branch'
    TTL_UNSET = -1
    CACHE_EXPIRE_IN = 1.day
    CACHE_LIMIT = 1000

    def fetch(ref_name)
      record = OpenSSL::Digest::SHA256.hexdigest(ref_name)

      Gitlab::Redis::Cache.with do |redis|
        cached_result = redis.hget(redis_key, record)

        break Gitlab::Redis::Boolean.decode(cached_result) unless cached_result.nil?

        value = yield

        redis.hset(redis_key, record, Gitlab::Redis::Boolean.encode(value))

        # We don't want to extend cache expiration time
        if redis.ttl(redis_key) == TTL_UNSET
          redis.expire(redis_key, CACHE_EXPIRE_IN)
        end

        # If the cache record has too many elements, then something went wrong and
        # it's better to drop the cache key.
        if redis.hlen(redis_key) > CACHE_LIMIT
          redis.unlink(redis_key)
        end

        value
      end
    end

    def refresh
      Gitlab::Redis::Cache.with { |redis| redis.unlink(redis_key) }
    end

    private

    def redis_key
      @redis_key ||= [CACHE_ROOT_KEY, @project.id].join(':')
    end
  end
end
