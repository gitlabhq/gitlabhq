# frozen_string_literal: true

module Gitlab
  module QueryLimiting
    # Middleware for reporting (or raising) when a request performs more than a
    # certain amount of database queries.
    class Middleware
      CONTROLLER_KEY = 'action_controller.instance'
      ENDPOINT_KEY = 'api.endpoint'

      def initialize(app)
        @app = app
      end

      def call(env)
        transaction, retval = ::Gitlab::QueryLimiting::Transaction.run do
          @app.call(env)
        end

        transaction.action = action_name(env)
        transaction.act_upon_results

        retval
      end

      def action_name(env)
        if env[CONTROLLER_KEY]
          action_for_rails(env)
        elsif env[ENDPOINT_KEY]
          action_for_grape(env)
        end
      end

      private

      def action_for_rails(env)
        controller = env[CONTROLLER_KEY]
        action = "#{controller.class.name}##{controller.action_name}"

        if controller.media_type == 'text/html'
          action
        else
          "#{action} (#{controller.media_type})"
        end
      end

      def action_for_grape(env)
        endpoint = env[ENDPOINT_KEY]
        route = begin
          endpoint.route
        rescue StandardError
          nil
        end

        "#{route.request_method} #{route.path}" if route
      end
    end
  end
end
