# frozen_string_literal: true

module Gitlab
  module Cluster
    class RackTimeoutObserver
      include ActionView::Helpers::SanitizeHelper
      TRANSITION_STATES = %i[ready active].freeze

      def initialize
        @counter = Gitlab::Metrics.counter(:rack_requests_total, 'Number of requests in a given rack state')
      end

      # returns the Proc to be used as the observer callback block
      def callback
        method(:log_timeout_exception)
      end

      private

      def log_timeout_exception(env)
        info = env[::Rack::Timeout::ENV_INFO_KEY]
        return unless info
        return if TRANSITION_STATES.include?(info.state)

        @counter.increment(labels(info, env))
      end

      def labels(info, env)
        params = controller_params(env) || grape_params(env) || {}

        {
          controller: sanitize(params['controller']),
          action: sanitize(params['action']),
          route: sanitize(params['route']),
          state: info.state
        }
      end

      def controller_params(env)
        env['action_dispatch.request.parameters']
      end

      def grape_params(env)
        endpoint = env[Grape::Env::API_ENDPOINT]
        route = endpoint&.route&.pattern&.origin
        return unless route

        { 'route' => route }
      end
    end
  end
end
