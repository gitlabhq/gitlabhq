# frozen_string_literal: true

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

        # Checks if we are caught-up with all the work
        def self.all_caught_up?(namespace, id)
          location = last_write_location_for(namespace, id)

          return true unless location

          load_balancer.select_up_to_date_host(location).tap do |found|
            ActiveSupport::Notifications.instrument('caught_up_replica_pick.load_balancing', { result: found } )

            unstick(namespace, id) if found
          end
        end

        # Selects hosts that have caught up with the primary. This ensures
        # atomic selection of the host to prevent the host list changing
        # in another thread.
        #
        # Returns true if one host was selected.
        def self.select_caught_up_replicas(namespace, id)
          location = last_write_location_for(namespace, id)

          # Unlike all_caught_up?, we return false if no write location exists.
          # We want to be sure we talk to a replica that has caught up for a specific
          # write location. If no such location exists, err on the side of caution.
          return false unless location

          if ::Feature.enabled?(:load_balancing_refine_load_balancer_methods)
            load_balancer.select_up_to_date_host(location).tap do |selected|
              unstick(namespace, id) if selected
            end
          else
            load_balancer.select_caught_up_hosts(location).tap do |selected|
              unstick(namespace, id) if selected
            end
          end
        end

        # Sticks to the primary if necessary, otherwise unsticks an object (if
        # it was previously stuck to the primary).
        def self.unstick_or_continue_sticking(namespace, id)
          Session.current.use_primary! unless all_caught_up?(namespace, id)
        end

        # Select a replica that has caught up with the primary. If one has not been
        # found, stick to the primary.
        def self.select_valid_host(namespace, id)
          replica_selected = select_caught_up_replicas(namespace, id)

          Session.current.use_primary! unless replica_selected
        end

        # Starts sticking to the primary for the given namespace and id, using
        # the latest WAL pointer from the primary.
        def self.stick(namespace, id)
          return unless LoadBalancing.enable?

          mark_primary_write_location(namespace, id)
          Session.current.use_primary!
        end

        def self.bulk_stick(namespace, ids)
          return unless LoadBalancing.enable?

          with_primary_write_location do |location|
            ids.each do |id|
              set_write_location_for(namespace, id, location)
            end
          end

          Session.current.use_primary!
        end

        def self.with_primary_write_location
          return unless LoadBalancing.configured?

          # Load balancing could be enabled for the Web application server,
          # but it's not activated for Sidekiq. We should update Redis with
          # the write location just in case load balancing is being used.
          location =
            if LoadBalancing.enable?
              load_balancer.primary_write_location
            else
              Gitlab::Database.get_write_location(ActiveRecord::Base.connection)
            end

          return if location.blank?

          yield(location)
        end

        def self.mark_primary_write_location(namespace, id)
          with_primary_write_location do |location|
            set_write_location_for(namespace, id, location)
          end
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
