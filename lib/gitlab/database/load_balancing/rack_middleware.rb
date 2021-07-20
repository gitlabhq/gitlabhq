# frozen_string_literal: true

module Gitlab
  module Database
    module LoadBalancing
      # Rack middleware to handle sticking when serving Rails requests. Grape
      # API calls are handled separately as different API endpoints need to
      # stick based on different objects.
      class RackMiddleware
        STICK_OBJECT = 'load_balancing.stick_object'

        # Unsticks or continues sticking the current request.
        #
        # This method also updates the Rack environment so #call can later
        # determine if we still need to stick or not.
        #
        # env - The Rack environment.
        # namespace - The namespace to use for sticking.
        # id - The identifier to use for sticking.
        def self.stick_or_unstick(env, namespace, id)
          return unless LoadBalancing.enable?

          Sticking.unstick_or_continue_sticking(namespace, id)

          env[STICK_OBJECT] ||= Set.new
          env[STICK_OBJECT] << [namespace, id]
        end

        def initialize(app)
          @app = app
        end

        def call(env)
          # Ensure that any state that may have run before the first request
          # doesn't linger around.
          clear

          unstick_or_continue_sticking(env)

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
        def unstick_or_continue_sticking(env)
          namespaces_and_ids = sticking_namespaces_and_ids(env)

          namespaces_and_ids.each do |namespace, id|
            Sticking.unstick_or_continue_sticking(namespace, id)
          end
        end

        # Determine if we need to stick after handling a request.
        def stick_if_necessary(env)
          namespaces_and_ids = sticking_namespaces_and_ids(env)

          namespaces_and_ids.each do |namespace, id|
            Sticking.stick_if_necessary(namespace, id)
          end
        end

        def clear
          load_balancer.release_host
          Session.clear_session
        end

        def load_balancer
          LoadBalancing.proxy.load_balancer
        end

        # Determines the sticking namespace and identifier based on the Rack
        # environment.
        #
        # For Rails requests this uses warden, but Grape and others have to
        # manually set the right environment variable.
        def sticking_namespaces_and_ids(env)
          warden = env['warden']

          if warden && warden.user
            [[:user, warden.user.id]]
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
