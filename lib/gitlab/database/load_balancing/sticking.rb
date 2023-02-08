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

        def initialize(load_balancer)
          @load_balancer = load_balancer
        end

        # Unsticks or continues sticking the current request.
        #
        # This method also updates the Rack environment so #call can later
        # determine if we still need to stick or not.
        #
        # env - The Rack environment.
        # namespace - The namespace to use for sticking.
        # id - The identifier to use for sticking.
        # model - The ActiveRecord model to scope sticking to.
        def stick_or_unstick_request(env, namespace, id)
          unstick_or_continue_sticking(namespace, id)

          env[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT] ||= Set.new
          env[::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT] << [self, namespace, id]
        end

        # Sticks to the primary if a write was performed.
        def stick_if_necessary(namespace, id)
          stick(namespace, id) if ::Gitlab::Database::LoadBalancing::Session.current.performed_write?
        end

        def all_caught_up?(namespace, id)
          location = last_write_location_for(namespace, id)

          return true unless location

          @load_balancer.select_up_to_date_host(location).tap do |found|
            ActiveSupport::Notifications.instrument(
              'caught_up_replica_pick.load_balancing',
              { result: found }
            )

            unstick(namespace, id) if found
          end
        end

        # Selects hosts that have caught up with the primary. This ensures
        # atomic selection of the host to prevent the host list changing
        # in another thread.
        #
        # Returns true if one host was selected.
        def select_caught_up_replicas(namespace, id)
          location = last_write_location_for(namespace, id)

          # Unlike all_caught_up?, we return false if no write location exists.
          # We want to be sure we talk to a replica that has caught up for a specific
          # write location. If no such location exists, err on the side of caution.
          return false unless location

          @load_balancer.select_up_to_date_host(location).tap do |selected|
            unstick(namespace, id) if selected
          end
        end

        # Sticks to the primary if necessary, otherwise unsticks an object (if
        # it was previously stuck to the primary).
        def unstick_or_continue_sticking(namespace, id)
          return if all_caught_up?(namespace, id)

          ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
        end

        # Select a replica that has caught up with the primary. If one has not been
        # found, stick to the primary.
        def select_valid_host(namespace, id)
          replica_selected =
            select_caught_up_replicas(namespace, id)

          ::Gitlab::Database::LoadBalancing::Session.current.use_primary! unless replica_selected
        end

        # Starts sticking to the primary for the given namespace and id, using
        # the latest WAL pointer from the primary.
        def stick(namespace, id)
          mark_primary_write_location(namespace, id)
          ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
        end

        def bulk_stick(namespace, ids)
          with_primary_write_location do |location|
            ids.each do |id|
              set_write_location_for(namespace, id, location)
            end
          end

          ::Gitlab::Database::LoadBalancing::Session.current.use_primary!
        end

        def with_primary_write_location
          # When only using the primary, there's no point in getting write
          # locations, as the primary is always in sync with itself.
          return if @load_balancer.primary_only?

          location = @load_balancer.primary_write_location

          return if location.blank?

          yield(location)
        end

        def mark_primary_write_location(namespace, id)
          with_primary_write_location do |location|
            set_write_location_for(namespace, id, location)
          end
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

        private

        def with_redis(&block)
          Gitlab::Redis::DbLoadBalancing.with(&block)
        end
      end
    end
  end
end
