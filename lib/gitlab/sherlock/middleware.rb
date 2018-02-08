module Gitlab
  module Sherlock
    # Rack middleware used for tracking request metrics.
    class Middleware
      CONTENT_TYPES = %r{text/html|application/json}i

      IGNORE_PATHS = %r{^/sherlock}

      def initialize(app)
        @app = app
      end

      # env - A Hash containing Rack environment details.
      def call(env)
        if instrument?(env)
          call_with_instrumentation(env)
        else
          @app.call(env)
        end
      end

      def call_with_instrumentation(env)
        trans = transaction_from_env(env)
        retval = trans.run { @app.call(env) }

        Sherlock.collection.add(trans)

        retval
      end

      def instrument?(env)
        !!(env['HTTP_ACCEPT'] =~ CONTENT_TYPES &&
           env['REQUEST_URI'] !~ IGNORE_PATHS)
      end

      def transaction_from_env(env)
        Transaction.new(env['REQUEST_METHOD'], env['REQUEST_URI'])
      end
    end
  end
end
