module Gitlab
  module Metrics
    # Rack middleware for tracking Rails and Grape requests.
    class RackMiddleware
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
          trans.finish
        end

        retval
      end

      def transaction_from_env(env)
        trans = WebTransaction.new(env)

        trans.set(:request_uri, filtered_path(env), false)
        trans.set(:request_method, env['REQUEST_METHOD'], false)

        trans
      end

      private

      def filtered_path(env)
        ActionDispatch::Request.new(env).filtered_path.presence || env['REQUEST_URI']
      end
    end
  end
end
