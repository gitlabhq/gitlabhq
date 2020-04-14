# frozen_string_literal: true

# Interface to the Redis-backed cache store to keep track of complete cache keys
# for a ReactiveCache resource.
module Gitlab
  class SetCache
    attr_reader :expires_in

    def initialize(expires_in: 2.weeks)
      @expires_in = expires_in
    end

    def cache_key(key)
      "#{key}:set"
    end

    # Returns the number of keys deleted by Redis
    def expire(*keys)
      return 0 if keys.empty?

      with do |redis|
        keys = keys.map { |key| cache_key(key) }
        unlink_or_delete(redis, keys)
      end
    end

    def exist?(key)
      with { |redis| redis.exists(cache_key(key)) }
    end

    def write(key, value)
      with do |redis|
        redis.pipelined do
          redis.sadd(cache_key(key), value)

          redis.expire(cache_key(key), expires_in)
        end
      end

      value
    end

    def read(key)
      with { |redis| redis.smembers(cache_key(key)) }
    end

    def include?(key, value)
      with { |redis| redis.sismember(cache_key(key), value) }
    end

    def ttl(key)
      with { |redis| redis.ttl(cache_key(key)) }
    end

    private

    def with(&blk)
      Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end

    def unlink_or_delete(redis, keys)
      if Feature.enabled?(:repository_set_cache_unlink, default_enabled: true)
        redis.unlink(*keys)
      else
        redis.del(*keys)
      end
    rescue ::Redis::CommandError => e
      Gitlab::ErrorTracking.log_exception(e)

      redis.del(*keys)
    end
  end
end
