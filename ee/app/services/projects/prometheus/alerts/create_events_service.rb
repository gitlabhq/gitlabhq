# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      # Persists a series of Prometheus alert events as list of PrometheusAlertEvent.
      class CreateEventsService < BaseService
        def execute
          create_events_from(alerts)
        end

        private

        def create_events_from(alerts)
          Array.wrap(alerts).map { |alert| create_event(alert) }.compact
        end

        def create_event(payload)
          return unless payload.respond_to?(:dig)

          status = payload.dig('status')
          return unless status

          started_at = validate_date(payload['startsAt'])
          return unless started_at

          ended_at = validate_date(payload['endsAt'])
          return unless ended_at

          gitlab_alert_id = payload.dig('labels', 'gitlab_alert_id')
          return unless gitlab_alert_id

          alert = project.prometheus_alerts.for_metric(gitlab_alert_id).first
          return unless alert

          payload_key = PrometheusAlertEvent.payload_key_for(gitlab_alert_id, started_at)
          event = PrometheusAlertEvent.find_or_initialize_by_payload_key(project, alert, payload_key)

          result = case status
                   when 'firing'
                     event.fire(started_at)
                   when 'resolved'
                     event.resolve(ended_at)
                   end

          event if result
        end

        def alerts
          params['alerts']
        end

        def validate_date(date)
          return unless date

          Time.parse(date)
          date
        rescue ArgumentError
        end
      end
    end
  end
end
