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

        attr_reader :load_balancer

        def initialize(load_balancer)
          @load_balancer = load_balancer
        end

        # Returns true if any caught up replica is found. This does not mean all replicas are caught up but the found
        # caught up replica will be stored in the SafeRequestStore available as LoadBalancer#host for future queries.
        # With use_primary_on_empty_location: true we will assume you need the primary if we can't find a matching
        # location for the namespace, id pair. You should only use use_primary_on_empty_location in rare cases because
        # we unstick once we find all replicas are caught up one time so it can be wasteful on the primary.
        def find_caught_up_replica(namespace, id, use_primary_on_failure: true, use_primary_on_empty_location: false)
          location = last_write_location_for(namespace, id)

          result = if location
                     up_to_date_result = @load_balancer.select_up_to_date_host(location)

                     unstick(namespace, id) if up_to_date_result == LoadBalancer::ALL_CAUGHT_UP

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
        def stick(namespace, id)
          with_primary_write_location do |location|
            set_write_location_for(namespace, id, location)
          end
          use_primary!
        end

        def bulk_stick(namespace, ids)
          with_primary_write_location do |location|
            ids.each do |id|
              set_write_location_for(namespace, id, location)
            end
          end

          use_primary!
        end

        private

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

        def set_write_location_for(namespace, id, location)
          with_redis do |redis|
            redis.set(redis_key_for(namespace, id), location, ex: EXPIRATION)
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
