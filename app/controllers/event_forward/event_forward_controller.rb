# frozen_string_literal: true

module EventForward
  class EventForwardController < BaseActionController
    DEDICATED_SUFFIX = 'dedicated'
    SELF_MANAGED_SUFFIX = 'sm'

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
        event_eligibility_checker.eligible?(event['se_ac'], event['aid'])
      end

      events_to_forward.each do |event|
        update_app_id(event)
        tracker.emit_event_payload(event)
      end

      logger.info("Enqueued events for forwarding. Count: #{events_to_forward.size}")
    end

    def update_app_id(event)
      app_id = event['aid']

      return unless app_id
      return if app_id.ends_with?(suffix)

      event['aid'] = "#{app_id}#{suffix}"
    end

    def logger
      @logger ||= EventForward::Logger.build
    end

    def suffix
      @suffix ||= if ::Gitlab::CurrentSettings.gitlab_dedicated_instance?
                    "_#{DEDICATED_SUFFIX}"
                  else
                    "_#{SELF_MANAGED_SUFFIX}"
                  end
    end
  end
end
