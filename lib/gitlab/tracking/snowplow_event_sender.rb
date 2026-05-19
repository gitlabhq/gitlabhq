# frozen_string_literal: true

module Gitlab
  module Tracking
    class SnowplowEventSender
      include Gitlab::Tracking::Helpers::SnowplowEventMetricLogger

      attr_reader :options, :endpoint

      def initialize(options, endpoint)
        @options = options.with_indifferent_access
        @endpoint = endpoint
      end

      def send_events(batch)
        emitter.send_requests(batch)
      end

      private

      def emitter
        @emitter ||= SnowplowTracker::Emitter.new(
          endpoint: endpoint,
          options: emitter_options
        )
      end

      def hostname
        endpoint
      end

      def emitter_options
        options.merge(
          on_success: method(:increment_successful_events_emissions),
          on_failure: method(:failure_callback)
        )
      end
    end
  end
end
