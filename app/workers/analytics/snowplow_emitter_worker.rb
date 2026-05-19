# frozen_string_literal: true

module Analytics
  class SnowplowEmitterWorker
    include ApplicationWorker

    queue_namespace :snowplow
    feature_category :product_analytics
    data_consistency :sticky
    urgency :low
    defer_on_database_health_signal :gitlab_main

    idempotent!
    worker_has_external_dependencies!

    def perform(event_batch, endpoint, options)
      Gitlab::AppLogger.info(
        message: "Sending snowplow events",
        endpoint: endpoint,
        origin: self.class.name,
        events_count: event_batch.count
      )

      Gitlab::Tracking::SnowplowEventSender.new(
        options,
        endpoint
      ).send_events(event_batch)
    end
  end
end
