# frozen_string_literal: true

module EventForward
  class EventForwardController < BaseActionController
    def forward
      process_events

      head :ok
    end

    private

    def process_events
      payload = Gitlab::Json.parse(request.raw_post)
      tracker = Gitlab::Tracking.tracker

      payload['data'].each do |event|
        tracker.emit_event_payload(event)
      end

      logger.info("Enqueued events for forwarding. Count: #{payload['data'].size}")
    end

    def logger
      @logger ||= EventForward::Logger.build
    end
  end
end
