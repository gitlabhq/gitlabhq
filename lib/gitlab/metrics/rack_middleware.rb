module Gitlab
  module Metrics
    # Rack middleware for tracking Rails requests.
    class RackMiddleware
      CONTROLLER_KEY = 'action_controller.instance'

      def initialize(app)
        @app = app
      end

      # env - A Hash containing Rack environment details.
      def call(env)
        trans  = transaction_from_env(env)
        retval = nil

        begin
          retval = trans.run { @app.call(env) }

        # Even in the event of an error we want to submit any metrics we
        # might've gathered up to this point.
        ensure
          if env[CONTROLLER_KEY]
            tag_controller(trans, env)
          end

          trans.finish
        end

        retval
      end

      def transaction_from_env(env)
        trans = Transaction.new

        trans.set(:request_uri, env['REQUEST_URI'])
        trans.set(:request_method, env['REQUEST_METHOD'])

        trans
      end

      def tag_controller(trans, env)
        controller   = env[CONTROLLER_KEY]
        trans.action = "#{controller.class.name}##{controller.action_name}"
      end
    end
  end
end
