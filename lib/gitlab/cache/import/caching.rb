# frozen_string_literal: true

module Gitlab
  module Cache
    module Import
      module Caching
        # The default timeout of the cache keys.
        TIMEOUT = 24.hours.to_i

        WRITE_IF_GREATER_SCRIPT = <<-EOF.strip_heredoc.freeze
        local key, value, ttl = KEYS[1], tonumber(ARGV[1]), ARGV[2]
        local existing = tonumber(redis.call("get", key))

        if existing == nil or value > existing then
          redis.call("set", key, value)
          redis.call("expire", key, ttl)
          return true
        else
          return false
        end
        EOF

        # Reads a cache key.
        #
        # If the key exists and has a non-empty value its TTL is refreshed
        # automatically.
        #
        # raw_key - The cache key to read.
        # timeout - The new timeout of the key if the key is to be refreshed.
        def self.read(raw_key, timeout: TIMEOUT)
          key = cache_key_for(raw_key)
          value = Redis::Cache.with { |redis| redis.get(key) }

          if value.present?
            # We refresh the expiration time so frequently used keys stick
            # around, removing the need for querying the database as much as
            # possible.
            #
            # A key may be empty when we looked up a GitHub user (for example) but
            # did not find a matching GitLab user. In that case we _don't_ want to
            # refresh the TTL so we automatically pick up the right data when said
            # user were to register themselves on the GitLab instance.
            Redis::Cache.with { |redis| redis.expire(key, timeout) }
          end

          value
        end

        # Reads an integer from the cache, or returns nil if no value was found.
        #
        # See Caching.read for more information.
        def self.read_integer(raw_key, timeout: TIMEOUT)
          value = read(raw_key, timeout: timeout)

          value.to_i if value.present?
        end

        # Sets a cache key to the given value.
        #
        # key - The cache key to write.
        # value - The value to set.
        # timeout - The time after which the cache key should expire.
        def self.write(raw_key, value, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.set(key, value, ex: timeout)
          end

          value
        end

        # Increment the integer value of a key by one.
        # Sets the value to zero if missing before incrementing
        #
        # key - The cache key to increment.
        # timeout - The time after which the cache key should expire.
        # @return - the incremented value
        def self.increment(raw_key, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.incr(key)
            redis.expire(key, timeout)
          end
        end

        # Adds a value to a set.
        #
        # raw_key - The key of the set to add the value to.
        # value - The value to add to the set.
        # timeout - The new timeout of the key.
        def self.set_add(raw_key, value, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.multi do |m|
              m.sadd(key, value)
              m.expire(key, timeout)
            end
          end
        end

        # Returns true if the given value is present in the set.
        #
        # raw_key - The key of the set to check.
        # value - The value to check for.
        def self.set_includes?(raw_key, value)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.sismember(key, value)
          end
        end

        # Returns the values of the given set.
        #
        # raw_key - The key of the set to check.
        def self.values_from_set(raw_key)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.smembers(key)
          end
        end

        # Sets multiple keys to given values.
        #
        # mapping - A Hash mapping the cache keys to their values.
        # key_prefix - prefix inserted before each key
        # timeout - The time after which the cache key should expire.
        def self.write_multiple(mapping, key_prefix: nil, timeout: TIMEOUT)
          Redis::Cache.with do |redis|
            redis.pipelined do |multi|
              mapping.each do |raw_key, value|
                key = cache_key_for("#{key_prefix}#{raw_key}")

                multi.set(key, value, ex: timeout)
              end
            end
          end
        end

        # Sets the expiration time of a key.
        #
        # raw_key - The key for which to change the timeout.
        # timeout - The new timeout.
        def self.expire(raw_key, timeout)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.expire(key, timeout)
          end
        end

        # Sets a key to the given integer but only if the existing value is
        # smaller than the given value.
        #
        # This method uses a Lua script to ensure the read and write are atomic.
        #
        # raw_key - The key to set.
        # value - The new value for the key.
        # timeout - The key timeout in seconds.
        #
        # Returns true when the key was overwritten, false otherwise.
        def self.write_if_greater(raw_key, value, timeout: TIMEOUT)
          key = cache_key_for(raw_key)
          val = Redis::Cache.with do |redis|
            redis
              .eval(WRITE_IF_GREATER_SCRIPT, keys: [key], argv: [value, timeout])
          end

          val ? true : false
        end

        # Adds a value to a hash.
        #
        # raw_key - The key of the hash to add to.
        # field - The field to add to the hash.
        # value - The field value to add to the hash.
        # timeout - The new timeout of the key.
        def self.hash_add(raw_key, field, value, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.multi do |m|
              m.hset(key, field, value)
              m.expire(key, timeout)
            end
          end
        end

        # Returns the values of the given hash.
        #
        # raw_key - The key of the set to check.
        def self.values_from_hash(raw_key)
          key = cache_key_for(raw_key)

          Redis::Cache.with do |redis|
            redis.hgetall(key)
          end
        end

        def self.cache_key_for(raw_key)
          "#{Redis::Cache::CACHE_NAMESPACE}:#{raw_key}"
        end
      end
    end
  end
end
