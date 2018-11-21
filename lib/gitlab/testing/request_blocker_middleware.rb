# frozen_string_literal: true

# rubocop:disable Style/ClassVars

# This is inspired by http://www.salsify.com/blog/engineering/tearing-capybara-ajax-tests
# Rack middleware that keeps track of the number of active requests and can block new requests.
module Gitlab
  module Testing
    class RequestBlockerMiddleware
      @@num_active_requests = Concurrent::AtomicFixnum.new(0)
      @@block_requests = Concurrent::AtomicBoolean.new(false)
      @@slow_requests = Concurrent::AtomicBoolean.new(false)

      # Returns the number of requests the server is currently processing.
      def self.num_active_requests
        @@num_active_requests.value
      end

      # Prevents the server from accepting new requests. Any new requests will return an HTTP
      # 503 status.
      def self.block_requests!
        @@block_requests.value = true
      end

      # Slows down incoming requests (useful for race conditions).
      def self.slow_requests!
        @@slow_requests.value = true
      end

      # Allows the server to accept requests again.
      def self.allow_requests!
        @@block_requests.value = false
        @@slow_requests.value = false
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        increment_active_requests

        if block_requests?
          block_request(env)
        else
          sleep 0.2 if slow_requests?
          @app.call(env)
        end

      ensure
        decrement_active_requests
      end

      private

      def block_requests?
        @@block_requests.true?
      end

      def slow_requests?
        @@slow_requests.true?
      end

      def block_request(env)
        [503, {}, []]
      end

      def increment_active_requests
        @@num_active_requests.increment
      end

      def decrement_active_requests
        @@num_active_requests.decrement
      end
    end
  end
end
