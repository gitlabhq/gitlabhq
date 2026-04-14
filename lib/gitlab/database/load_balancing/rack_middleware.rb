# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Rack middleware to handle sticking when serving Rails requests. Grape
      # API calls are handled separately as different API endpoints need to
      # stick based on different objects.
      class RackMiddleware
        STICK_OBJECT = 'load_balancing.stick_object'

        def initialize(app)
          @app = app
        end

        def call(env)
          # Ensure that any state that may have run before the first request
          # doesn't linger around.
          clear

          find_caught_up_replica(env)

          result = @app.call(env)

          ActiveSupport::Notifications.instrument('web_transaction_completed.load_balancing')

          stick_if_necessary(env)

          result
        ensure
          clear
        end

        # Determine if we need to stick based on currently available user data.
        #
        # Typically this code will only be reachable for Rails requests as
        # Grape data is not yet available at this point.
        def find_caught_up_replica(env)
          # In this call we accidentally preload the user object via warden
          namespaces_and_ids = sticking_namespaces(env)

          namespaces_and_ids.each do |(sticking, namespace, id)|
            sticking.find_caught_up_replica(namespace, id)
          end
        end

        def grab_user_id_enabled?
          Feature.enabled?(:grab_user_id_from_warden_session, Feature.current_request)
        end

        # Determine if we need to stick after handling a request.
        def stick_if_necessary(env)
          namespaces_and_ids = sticking_namespaces(env)

          namespaces_and_ids.each do |sticking, namespace, id|
            lb = sticking.load_balancer
            sticking.stick(namespace, id) if ::Gitlab::Database::LoadBalancing::SessionMap.current(lb).performed_write?
          end
        end

        def clear
          ::Gitlab::Database::LoadBalancing.release_hosts(force: true)
          ::Gitlab::Database::LoadBalancing::SessionMap.clear_session
        end

        # Determines the sticking namespace and identifier based on the Rack
        # environment.
        #
        # For Rails requests this uses warden, but Grape and others have to
        # manually set the right environment variable.
        def sticking_namespaces(env)
          warden = env['warden']

          user_id = if grab_user_id_enabled?
                      # Retrieves the current user's ID directly from the Rack session without
                      # loading the User record. This avoids accidentally caching the user object
                      # before replica sticking is established, which would cause it to be loaded
                      # from a random replica rather than a caught-up one.
                      env['rack.session']&.dig(Warden::SessionSerializer.new(env).key_for(:user), 0, 0)
                    else
                      warden && warden.user && warden.user.id
                    end

          if user_id
            # When sticking per user, _only_ sticking the main connection could
            # result in the application trying to read data from a different
            # connection, while that data isn't available yet.
            #
            # To prevent this from happening, we scope sticking to all the
            # models that support load balancing. In the future (if we
            # determined this to be OK) we may be able to relax this.
            ::Gitlab::Database::LoadBalancing.base_models.map do |model|
              [model.sticking, :user, user_id]
            end
          elsif env[STICK_OBJECT].present?
            env[STICK_OBJECT].to_a
          else
            []
          end
        end
      end
    end
  end
end
