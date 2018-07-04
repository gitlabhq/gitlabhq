module Gitlab
  class ShardHealthCache
    HEALTHY_SHARDS_KEY = 'gitlab-healthy-shards'.freeze
    HEALTHY_SHARDS_TIMEOUT = 300

    # Clears the Redis set storing the list of healthy shards
    def self.clear
      Gitlab::Redis::Cache.with { |redis| redis.del(HEALTHY_SHARDS_KEY) }
    end

    # Updates the list of healthy shards using a Redis set
    #
    # shards - An array of shard names to store
    def self.update(shards)
      Gitlab::Redis::Cache.with do |redis|
        redis.multi do |m|
          m.del(HEALTHY_SHARDS_KEY)
          shards.each { |shard_name| m.sadd(HEALTHY_SHARDS_KEY, shard_name) }
          m.expire(HEALTHY_SHARDS_KEY, HEALTHY_SHARDS_TIMEOUT)
        end
      end
    end

    # Returns an array of strings of healthy shards
    def self.cached_healthy_shards
      Gitlab::Redis::Cache.with { |redis| redis.smembers(HEALTHY_SHARDS_KEY) }
    end

    # Checks whether the given shard name is in the list of healthy shards.
    #
    # shard_name - The string to check
    def self.healthy_shard?(shard_name)
      Gitlab::Redis::Cache.with { |redis| redis.sismember(HEALTHY_SHARDS_KEY, shard_name) }
    end

    # Returns the number of healthy shards in the Redis set
    def self.healthy_shard_count
      Gitlab::Redis::Cache.with { |redis| redis.scard(HEALTHY_SHARDS_KEY) }
    end
  end
end
