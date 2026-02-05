# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Module used for handling sticking connections to a primary, if
      # necessary.
      class Sticking
        # The number of seconds after which a session should stop reading from
        # the primary.
        EXPIRATION = 30

        ATOMIC_UNSTICK_SCRIPT = <<~LUA
          local key = KEYS[1]
          local expected_location = ARGV[1]
          local current_location = redis.call('GET', key)

          if current_location == expected_location then
            redis.call('DEL', key)
            return 1
          else
            return 0
          end
        LUA

        ATOMIC_STICK_SCRIPT = <<~LUA
          -- Converts a PostgreSQL LSN string (e.g., "0/16B3A78") to an integer for comparison
          -- We keep them separate to avoid precision loss with 64-bit integers in Lua's doubles
          local function lsn_to_int(lsn)
            -- Extract the high and low hex parts from the LSN format "high/low"
            local high, low = string.match(lsn, "(%x+)/(%x+)")
            if not high or not low then
              return nil, nil
            end
            -- Convert hex to int: high part shifted left by 32 bits (4294967296 = 2^32) plus low part
            return tonumber(high, 16), tonumber(low, 16)
          end

          --  Compares two LSNs by their high/low parts. Returns true if first LSN is greater.
          local function lsn_greater_than(high1, low1, high2, low2)
            if high1 ~= high2 then
              return high1 > high2
            end
            return low1 > low2
          end

          local key = KEYS[1]
          local new_lsn_str = ARGV[1]
          local ttl = tonumber(ARGV[2])

          local new_high, new_low = lsn_to_int(new_lsn_str)

          assert(new_high, "ERR ARGV[1] must be a valid LSN (e.g. 0/16B3A78)")
          assert(ttl and ttl > 0, "ERR ARGV[2] (TTL) must be a positive integer")

          local current_lsn_str = redis.call("get", key)
          local current_high, current_low =  nil, nil
          if current_lsn_str then
            current_high, current_low = lsn_to_int(current_lsn_str)
          end

          if not current_high or lsn_greater_than(new_high, new_low, current_high, current_low) then
            redis.call("set", key, new_lsn_str, "ex", ttl)
            return 1
          else
            redis.call("expire", key, ttl)
            return 0
          end
        LUA

        attr_reader :load_balancer

        def initialize(load_balancer)
          @load_balancer = load_balancer
        end

        # Returns true if any caught up replica is found. This does not mean all replicas are caught up but the found
        # caught up replica will be stored in the SafeRequestStore available as LoadBalancer#host for future queries.
        # With use_primary_on_empty_location: true we will assume you need the primary if we can't find a matching
        # location for the namespace, id pair. You should only use use_primary_on_empty_location in rare cases because
        # we unstick once we find all replicas are caught up one time so it can be wasteful on the primary.
        # If hash_id is true then we only store a hash of id in Redis. This is useful for sensitive data like API
        # tokens.
        def find_caught_up_replica(
          namespace, id,
          use_primary_on_failure: true,
          use_primary_on_empty_location: false,
          hash_id: false)
          id = id_as_hash(id) if hash_id

          location = last_write_location_for(namespace, id)

          result = if location
                     up_to_date_result = @load_balancer.select_up_to_date_host(location)

                     unstick_if_caught_up(namespace, id, location) if up_to_date_result == LoadBalancer::ALL_CAUGHT_UP

                     up_to_date_result != LoadBalancer::NONE_CAUGHT_UP
                   else
                     # Some callers want to err on the side of caution and be really sure that a caught up replica was
                     # found. If we did not have any location to check then we must force `use_primary!` if they they
                     # use_primary_on_empty_location
                     !use_primary_on_empty_location
                   end

          use_primary! if !result && use_primary_on_failure

          result
        end

        # Starts sticking to the primary for the given namespace and id, using
        # the latest WAL pointer from the primary.
        # If hash_id is true then we only store a hash of id in Redis. This is useful for sensitive data like API
        # tokens.
        def stick(namespace, id, hash_id: false)
          id = id_as_hash(id) if hash_id

          with_primary_write_location do |location|
            set_write_location_for(namespace, id, location)
          end
          use_primary!
        end

        def bulk_stick(namespace, ids, hash_id: false)
          with_primary_write_location do |location|
            ids.each do |id|
              id = id_as_hash(id) if hash_id

              set_write_location_for(namespace, id, location)
            end
          end
          use_primary!
        end

        private

        # Sometimes we use sensitive data like API tokens as sticking keys. We do not want or need to store those in
        # Redis so we just use a hash instead.
        def id_as_hash(id)
          Digest::SHA256.hexdigest(id.to_s)
        end

        def with_primary_write_location
          # When only using the primary, there's no point in getting write
          # locations, as the primary is always in sync with itself.
          return if @load_balancer.primary_only?

          location = @load_balancer.primary_write_location

          return if location.blank?

          yield(location)
        end

        def unstick(namespace, id)
          with_redis do |redis|
            redis.del(redis_key_for(namespace, id))
          end
        end

        # Atomically unstick only if the sticking point hasn't changed since we read it.
        # This prevents a race condition where a concurrent request sets a new sticking point
        # after we've verified all replicas are caught up but before we unstick.
        #
        # Returns 1 if unstick was performed, 0 if the value changed (indicating a new write).
        def unstick_if_caught_up(namespace, id, expected_location)
          with_redis do |redis|
            redis.eval(ATOMIC_UNSTICK_SCRIPT, keys: [redis_key_for(namespace, id)], argv: [expected_location])
          end
        end

        def set_write_location_for(namespace, id, location)
          if atomic_sticking_enabled?
            set_atomic_write_location_for(namespace, id, location)
          else
            with_redis do |redis|
              redis.set(redis_key_for(namespace, id), location, ex: EXPIRATION)
            end
          end
        end

        def atomic_sticking_enabled?
          Feature.enabled?(:db_load_balancing_atomic_sticking, Feature.current_request)
        end

        # Atomically updates the stick LSN if the new value is higher, ensuring
        # clients always stick to the most recent write position. This prevents race conditions
        # that can cause LSN values to regress leading to stale reads from the replicas.
        #
        # Returns 1 if the LSN was updated, 0 if the value remains unchanged (just refresh the TTL)
        def set_atomic_write_location_for(namespace, id, location)
          with_redis do |redis|
            redis.eval(ATOMIC_STICK_SCRIPT, keys: [redis_key_for(namespace, id)],
              argv: [location, EXPIRATION])
          end
        end

        def last_write_location_for(namespace, id)
          with_redis do |redis|
            redis.get(redis_key_for(namespace, id))
          end
        end

        def redis_key_for(namespace, id)
          name = @load_balancer.name

          "database-load-balancing/write-location/#{name}/#{namespace}/#{id}"
        end

        def with_redis(&block)
          Gitlab::Redis::DbLoadBalancing.with(&block)
        end

        def use_primary!
          ::Gitlab::Database::LoadBalancing::SessionMap.current(@load_balancer).use_primary!
        end
      end
    end
  end
end
