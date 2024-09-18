# frozen_string_literal: true

module Ci
  module JobToken
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        response = @app.call(env)

        # We only log authorizations leading to successful requests.
        Ci::JobToken::Authorization.log_captures_async if success?(response[0])

        response
      end

      private

      def success?(status)
        (200..299).cover?(status)
      end
    end
  end
end
