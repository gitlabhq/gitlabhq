module Gitlab
  module Sherlock
    # Rack middleware used for tracking request metrics.
    class Middleware
      CONTENT_TYPES = /text\/html|application\/json/i

      IGNORE_PATHS = %r{^/sherlock}

      def initialize(app)
        @app = app
      end

      def call(env)
        if instrument?(env)
          call_with_instrumentation(env)
        else
          @app.call(env)
        end
      end

      def call_with_instrumentation(env)
        trans = Transaction.new(env['REQUEST_METHOD'], env['REQUEST_URI'])
        retval = trans.run { @app.call(env) }

        Sherlock.collection.add(trans)

        retval
      end

      def instrument?(env)
        !!(env['HTTP_ACCEPT'] =~ CONTENT_TYPES &&
           env['REQUEST_URI'] !~ IGNORE_PATHS)
      end
    end
  end
end
