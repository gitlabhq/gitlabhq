module Gitlab
  module Database
    module LoadBalancing
      # Module used for handling sticking connections to a primary, if
      # necessary.
      #
      # ## Examples
      #
      # Sticking a user to the primary:
      #
      #     Sticking.stick_if_necessary(:user, current_user.id)
      #
      # To unstick if possible, or continue using the primary otherwise:
      #
      #     Sticking.unstick_or_continue_sticking(:user, current_user.id)
      module Sticking
        # The number of seconds after which a session should stop reading from
        # the primary.
        EXPIRATION = 30

        # Sticks to the primary if a write was performed.
        def self.stick_if_necessary(namespace, id)
          return unless LoadBalancing.enable?

          stick(namespace, id) if Session.current.performed_write?
        end

        # Checks if we were able to caught-up with all the work
        def self.all_caught_up?(namespace, id)
          location = last_write_location_for(namespace, id)

          return true unless location

          load_balancer.all_caught_up?(location).tap do |caught_up|
            unstick(namespace, id) if caught_up
          end
        end

        # Sticks to the primary if necessary, otherwise unsticks an object (if
        # it was previously stuck to the primary).
        def self.unstick_or_continue_sticking(namespace, id)
          Session.current.use_primary! unless all_caught_up?(namespace, id)
        end

        # Starts sticking to the primary for the given namespace and id, using
        # the latest WAL pointer from the primary.
        def self.stick(namespace, id)
          return unless LoadBalancing.enable?

          location = load_balancer.primary_write_location

          set_write_location_for(namespace, id, location)

          Session.current.use_primary!
        end

        # Stops sticking to the primary.
        def self.unstick(namespace, id)
          Gitlab::Redis::SharedState.with do |redis|
            redis.del(redis_key_for(namespace, id))
          end
        end

        def self.set_write_location_for(namespace, id, location)
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(redis_key_for(namespace, id), location, ex: EXPIRATION)
          end
        end

        def self.last_write_location_for(namespace, id)
          Gitlab::Redis::SharedState.with do |redis|
            redis.get(redis_key_for(namespace, id))
          end
        end

        def self.redis_key_for(namespace, id)
          "database-load-balancing/write-location/#{namespace}/#{id}"
        end

        def self.load_balancer
          LoadBalancing.proxy.load_balancer
        end
      end
    end
  end
end
