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
      "#{cache_namespace}:#{key}:set"
    end

    # Returns the number of keys deleted by Redis
    def expire(*keys)
      return 0 if keys.empty?

      with do |redis|
        keys_to_expire = keys.map { |key| cache_key(key) }

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          redis.unlink(*keys_to_expire)
        end
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

    # Like include?, but also tells us if the cache was populated when it ran
    # by returning two booleans: [member_exists, set_exists]
    def try_include?(key, value)
      full_key = cache_key(key)

      with do |redis|
        redis.multi do
          redis.sismember(full_key, value)
          redis.exists(full_key)
        end
      end
    end

    def ttl(key)
      with { |redis| redis.ttl(cache_key(key)) }
    end

    private

    def with(&blk)
      Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end

    def cache_namespace
      Gitlab::Redis::Cache::CACHE_NAMESPACE
    end
  end
end
