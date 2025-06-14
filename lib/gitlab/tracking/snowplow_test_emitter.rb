# frozen_string_literal: true

module Gitlab
  module Tracking
    class SnowplowTestEmitter < SnowplowTracker::Emitter
      extend ::Gitlab::Utils::Override

      # Override send_requests to prevent HTTP requests in test environment
      # This allows event tracking to work normally without making actual HTTP calls
      override :send_requests
      def send_requests(events)
        events.size
      end
    end
  end
end
