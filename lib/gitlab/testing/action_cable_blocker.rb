# frozen_string_literal: true

# rubocop:disable Style/ClassVars

# This is inspired by http://www.salsify.com/blog/engineering/tearing-capybara-ajax-tests
# Rack middleware that keeps track of the number of active requests and can block new requests.
module Gitlab
  module Testing
    class ActionCableBlocker
      @@num_active_requests = Concurrent::AtomicFixnum.new(0)
      @@block_requests = Concurrent::AtomicBoolean.new(false)

      # Returns the number of requests the server is currently processing.
      def self.num_active_requests
        @@num_active_requests.value
      end

      # Prevents the server from accepting new requests. Any new requests will be skipped.
      def self.block_requests!
        @@block_requests.value = true
      end

      # Allows the server to accept requests again.
      def self.allow_requests!
        @@block_requests.value = false
      end

      def self.install
        ::ActionCable::Server::Worker.set_callback :work, :around do |_, inner|
          @@num_active_requests.increment

          inner.call if @@block_requests.false?
        ensure
          @@num_active_requests.decrement
        end
      end
    end
  end
end
# rubocop:enable Style/ClassVars
