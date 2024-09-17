# frozen_string_literal: true

module Gitlab
  module Cache
    module Import
      module Caching
        # The default timeout of the cache keys.
        TIMEOUT = 24.hours.to_i

        LONGER_TIMEOUT = 72.hours.to_i

        SHORTER_TIMEOUT = 15.minutes.to_i

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
          value = with_redis { |redis| redis.get(key) }

          if value.present?
            # We refresh the expiration time so frequently used keys stick
            # around, removing the need for querying the database as much as
            # possible.
            #
            # A key may be empty when we looked up a GitHub user (for example) but
            # did not find a matching GitLab user. In that case we _don't_ want to
            # refresh the TTL so we automatically pick up the right data when said
            # user were to register themselves on the GitLab instance.
            with_redis { |redis| redis.expire(key, timeout) }
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
        # raw_key - The cache key to write.
        # value - The value to set.
        # timeout - The time after which the cache key should expire.
        def self.write(raw_key, value, timeout: TIMEOUT)
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.set(key, value, ex: timeout)
          end

          value
        end

        # Increment the integer value of a key by one.
        # Sets the value to zero if missing before incrementing
        #
        # raw_key - The cache key to increment.
        # timeout - The time after which the cache key should expire.
        # @return - the incremented value
        def self.increment(raw_key, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            value = redis.incr(key)
            redis.expire(key, timeout)

            value
          end
        end

        # Increment the integer value of a key by the given value.
        # Sets the value to zero if missing before incrementing
        #
        # raw_key - The cache key to increment.
        # value - The value to increment the key
        # timeout - The time after which the cache key should expire.
        # @return - the incremented value
        def self.increment_by(raw_key, value, timeout: TIMEOUT)
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.incrby(key, value)
            redis.expire(key, timeout)
          end
        end

        # Adds a value to a set.
        #
        # raw_key - The key of the set to add the value to.
        # value - The value to add to the set.
        # timeout - The new timeout of the key.
        def self.set_add(raw_key, value, timeout: TIMEOUT)
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.multi do |m|
              m.sadd?(key, value)
              m.expire(key, timeout)
            end
          end
        end

        # Returns true if the given value is present in the set.
        #
        # raw_key - The key of the set to check.
        # value - The value to check for.
        def self.set_includes?(raw_key, value)
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.sismember(key, value || value.to_s)
          end
        end

        # Returns the number of values in the set.
        #
        # raw_key - The key of the set to check.
        def self.set_count(raw_key)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.scard(key)
          end
        end

        # Returns the values of the given set.
        #
        # raw_key - The key of the set to check.
        def self.values_from_set(raw_key)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.smembers(key)
          end
        end

        # Returns a limited number of random values from the set.
        #
        # raw_key - The key of the set to check.
        # limit - Number of values to return (default: 1).
        def self.limited_values_from_set(raw_key, limit: 1)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.srandmember(key, limit)
          end
        end

        # Removes the given values from the set.
        #
        # raw_key - The key of the set to check.
        # values - Array of values to remove from set.
        def self.set_remove(raw_key, values = [])
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.srem(key, values)
          end
        end

        # Sets multiple keys to given values.
        #
        # mapping - A Hash mapping the cache keys to their values.
        # key_prefix - prefix inserted before each key
        # timeout - The time after which the cache key should expire.
        def self.write_multiple(mapping, key_prefix: nil, timeout: TIMEOUT)
          with_redis do |redis|
            Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
              redis.pipelined do |pipeline|
                mapping.each do |raw_key, value|
                  key = cache_key_for("#{key_prefix}#{raw_key}")

                  validate_redis_value!(value)

                  pipeline.set(key, value, ex: timeout)
                end
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

          with_redis do |redis|
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
          validate_redis_value!(value)

          key = cache_key_for(raw_key)
          val = with_redis do |redis|
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
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.multi do |m|
              m.hset(key, field, value)
              m.expire(key, timeout)
            end
          end
        end

        # Returns the values of the given hash.
        #
        # raw_key - The key of the hash to check.
        def self.values_from_hash(raw_key)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.hgetall(key)
          end
        end

        # Returns a single value of the given hash.
        #
        # raw_key - The key of the hash to check.
        # field - The field to get from the hash.
        def self.value_from_hash(raw_key, field, timeout: TIMEOUT)
          key = cache_key_for(raw_key)

          value = with_redis { |redis| redis.hget(key, field) }

          with_redis { |redis| redis.expire(key, timeout) } if value.present?

          value
        end

        # Increments value of a field in a hash
        #
        # raw_key - The key of the hash to add to.
        # field - The field to increment.
        # value - The field value to add to the hash.
        # timeout - The new timeout of the key.
        def self.hash_increment(raw_key, field, value, timeout: TIMEOUT)
          return if value.to_i <= 0

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.multi do |m|
              m.hincrby(key, field, value.to_i)
              m.expire(key, timeout)
            end
          end
        end

        # Adds a value to a list.
        #
        # raw_key - The key of the list to add to.
        # value - The field value to add to the list.
        # timeout - The new timeout of the key.
        # limit - The maximum number of members in the list. Older members will be trimmed to this limit.
        def self.list_add(raw_key, value, timeout: TIMEOUT, limit: nil)
          validate_redis_value!(value)

          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.multi do |m|
              m.rpush(key, value)
              m.ltrim(key, -limit, -1) if limit
              m.expire(key, timeout)
            end
          end
        end

        # Returns the values of the given list.
        #
        # raw_key - The key of the list.
        def self.values_from_list(raw_key)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.lrange(key, 0, -1)
          end
        end

        # Deletes a key
        #
        # raw_key - Key name
        def self.del(raw_key)
          key = cache_key_for(raw_key)

          with_redis do |redis|
            redis.del(key)
          end
        end

        def self.cache_key_for(raw_key)
          "#{Redis::Cache::CACHE_NAMESPACE}:#{raw_key}"
        end

        def self.with_redis(&block)
          Gitlab::Redis::SharedState.with(&block) # rubocop:disable CodeReuse/ActiveRecord -- This is not AR
        end

        def self.validate_redis_value!(value)
          value_as_string = value.to_s
          return if value_as_string.is_a?(String)

          raise "Value '#{value_as_string}' of type '#{value_as_string.class}' for '#{value.inspect}' is not a String"
        end
      end
    end
  end
end
