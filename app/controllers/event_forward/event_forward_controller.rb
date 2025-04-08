# frozen_string_literal: true

module EventForward
  class EventForwardController < BaseActionController
    def forward
      if ::Feature.enabled?(:collect_product_usage_events, :instance)
        process_events

        head :ok
      else
        head :not_found
      end
    end

    private

    def process_events
      tracker = Gitlab::Tracking.tracker
      event_eligibility_checker = Gitlab::Tracking::EventEligibilityChecker.new

      payload = Gitlab::Json.parse(request.raw_post)

      events_to_forward = payload['data'].select do |event|
        event_eligibility_checker.eligible?(event['se_ac'])
      end

      events_to_forward.each do |event|
        tracker.emit_event_payload(event)
      end

      logger.info("Enqueued events for forwarding. Count: #{events_to_forward.size}")
    end

    def logger
      @logger ||= EventForward::Logger.build
    end
  end
end
