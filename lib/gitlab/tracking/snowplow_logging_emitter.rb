# frozen_string_literal: true

module Gitlab
  module Tracking
    class SnowplowLoggingEmitter < SnowplowTracker::AsyncEmitter
      extend ::Gitlab::Utils::Override

      override :send_requests
      def send_requests(events)
        events.each do |event|
          event_logger.info(message: 'sending event', payload: event.to_json)
        end

        super
      end

      private

      def event_logger
        @event_logger ||= ::Gitlab::Tracking::SnowplowEventLogger.build
      end
    end
  end
end
