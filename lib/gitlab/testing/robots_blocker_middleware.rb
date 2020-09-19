# frozen_string_literal: true

# rubocop:disable Style/ClassVars
module Gitlab
  module Testing
    class RobotsBlockerMiddleware
      @@block_requests = Concurrent::AtomicBoolean.new(false)

      # Block requests according to robots.txt.
      # Any new requests disallowed by robots.txt will return an HTTP 503 status.
      def self.block_requests!
        @@block_requests.value = true
      end

      # Allows the server to accept requests again.
      def self.allow_requests!
        @@block_requests.value = false
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)

        if block_requests? && Gitlab::RobotsTxt.disallowed?(request.path_info)
          block_request(env)
        else
          @app.call(env)
        end
      end

      private

      def block_requests?
        @@block_requests.true?
      end

      def block_request(env)
        [503, {}, []]
      end
    end
  end
end
