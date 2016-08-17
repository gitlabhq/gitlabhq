module Gitlab
  module Metrics
    # Rack middleware for tracking Rails and Grape requests.
    class RackMiddleware
      CONTROLLER_KEY = 'action_controller.instance'
      ENDPOINT_KEY   = 'api.endpoint'

      def initialize(app)
        @app = app
      end

      # env - A Hash containing Rack environment details.
      def call(env)
        trans  = transaction_from_env(env)
        retval = nil

        begin
          retval = trans.run { @app.call(env) }

        rescue Exception => error # rubocop: disable Lint/RescueException
          trans.add_event(:rails_exception)

          raise error
        # Even in the event of an error we want to submit any metrics we
        # might've gathered up to this point.
        ensure
          if env[CONTROLLER_KEY]
            tag_controller(trans, env)
          elsif env[ENDPOINT_KEY]
            tag_endpoint(trans, env)
          end

          trans.finish
        end

        retval
      end

      def transaction_from_env(env)
        trans = Transaction.new

        trans.set(:request_uri, filtered_path(env))
        trans.set(:request_method, env['REQUEST_METHOD'])

        trans
      end

      def tag_controller(trans, env)
        controller   = env[CONTROLLER_KEY]
        trans.action = "#{controller.class.name}##{controller.action_name}"
      end

      def tag_endpoint(trans, env)
        endpoint = env[ENDPOINT_KEY]
        path = endpoint_paths_cache[endpoint.route.route_method][endpoint.route.route_path]
        trans.action = "Grape##{endpoint.route.route_method} #{path}"
      end

      private

      def filtered_path(env)
        ActionDispatch::Request.new(env).filtered_path.presence || env['REQUEST_URI']
      end

      def endpoint_paths_cache
        @endpoint_paths_cache ||= Hash.new do |hash, http_method|
          hash[http_method] = Hash.new do |inner_hash, raw_path|
            inner_hash[raw_path] = endpoint_instrumentable_path(raw_path)
          end
        end
      end

      def endpoint_instrumentable_path(raw_path)
        raw_path.sub('(.:format)', '').sub('/:version', '')
      end
    end
  end
end
