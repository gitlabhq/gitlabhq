module Gitlab
  module Database
    module LoadBalancing
      # Rack middleware for managing load balancing.
      class RackMiddleware
        SESSION_KEY = :gitlab_load_balancer

        # The number of seconds after which a session should stop reading from
        # the primary.
        EXPIRATION = 30

        def initialize(app)
          @app = app
        end

        def call(env)
          # Ensure that any state that may have run before the first request
          # doesn't linger around.
          clear

          user = user_for_request(env)

          check_primary_requirement(user) if user

          result = @app.call(env)

          assign_primary_for_user(user) if Session.current.use_primary? && user

          result
        ensure
          clear
        end

        # Checks if we need to use the primary for the current user.
        def check_primary_requirement(user)
          location = last_write_location_for(user)

          return unless location

          if load_balancer.all_caught_up?(location)
            delete_write_location_for(user)
          else
            Session.current.use_primary!
          end
        end

        def assign_primary_for_user(user)
          set_write_location_for(user, load_balancer.primary_write_location)
        end

        def clear
          load_balancer.release_host
          Session.clear_session
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end

        # Returns the User object for the currently authenticated user, if any.
        def user_for_request(env)
          api = env['api.endpoint']
          warden = env['warden']

          if api && api.respond_to?(:current_user)
            # The current request is an API request. In this case we can use our
            # `current_user` helper method.
            api.current_user
          elsif warden && warden.user
            # Used by the Rails app, and sometimes by the API.
            warden.user
          else
            nil
          end
        end

        def last_write_location_for(user)
          Gitlab::Redis.with do |redis|
            redis.get(redis_key_for(user))
          end
        end

        def delete_write_location_for(user)
          Gitlab::Redis.with do |redis|
            redis.del(redis_key_for(user))
          end
        end

        def set_write_location_for(user, location)
          Gitlab::Redis.with do |redis|
            redis.set(redis_key_for(user), location, ex: EXPIRATION)
          end
        end

        def redis_key_for(user)
          "database-load-balancing/write-location/#{user.id}"
        end
      end
    end
  end
end
