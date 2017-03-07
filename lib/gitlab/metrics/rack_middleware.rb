module Gitlab
  module Metrics
    # Rack middleware for tracking Rails and Grape requests.
    class RackMiddleware
      CONTROLLER_KEY = 'action_controller.instance'.freeze
      ENDPOINT_KEY   = 'api.endpoint'.freeze
      CONTENT_TYPES = {
        'text/html' => :html,
        'text/plain' => :txt,
        'application/json' => :json,
        'text/js' => :js,
        'application/atom+xml' => :atom,
        'image/png' => :png,
        'image/jpeg' => :jpeg,
        'image/gif' => :gif,
        'image/svg+xml' => :svg
      }.freeze

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
        controller = env[CONTROLLER_KEY]
        action = "#{controller.class.name}##{controller.action_name}"
        suffix = CONTENT_TYPES[controller.content_type]

        if suffix && suffix != :html
          action += ".#{suffix}"
        end

        trans.action = action
      end

      def tag_endpoint(trans, env)
        endpoint = env[ENDPOINT_KEY]

        begin
          route = endpoint.route
        rescue
          # endpoint.route is calling env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
          # but env[Grape::Env::GRAPE_ROUTING_ARGS] is nil in the case of a 405 response
          # so we're rescuing exceptions and bailing out
        end

        if route
          path = endpoint_paths_cache[route.request_method][route.path]
          trans.action = "Grape##{route.request_method} #{path}"
        end
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
