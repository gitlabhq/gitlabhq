# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Rails and Grape requests.
    class RackMiddleware
      def initialize(app)
        @app = app
      end

      # env - A Hash containing Rack environment details.
      def call(env)
        trans = Gitlab::Metrics::WebTransaction.new(env)

        begin
          retval = trans.run { @app.call(env) }

        rescue Exception => error # rubocop: disable Lint/RescueException
          trans.add_event(:rails_exception)

          raise error
        end

        retval
      end
    end
  end
end
