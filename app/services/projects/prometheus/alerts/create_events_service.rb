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
          parsed_alert = Gitlab::Alerting::Alert.new(project: project, payload: payload)

          return unless parsed_alert.valid?

          if parsed_alert.gitlab_managed?
            create_managed_prometheus_alert_event(parsed_alert)
          else
            create_self_managed_prometheus_alert_event(parsed_alert)
          end
        end

        def alerts
          params['alerts']
        end

        def find_alert(metric)
          Projects::Prometheus::AlertsFinder
            .new(project: project, metric: metric)
            .execute
            .first
        end

        def create_managed_prometheus_alert_event(parsed_alert)
          alert = find_alert(parsed_alert.metric_id)
          event = PrometheusAlertEvent.find_or_initialize_by_payload_key(parsed_alert.project, alert, parsed_alert.gitlab_fingerprint)

          set_status(parsed_alert, event)
        end

        def create_self_managed_prometheus_alert_event(parsed_alert)
          event = SelfManagedPrometheusAlertEvent.find_or_initialize_by_payload_key(parsed_alert.project, parsed_alert.gitlab_fingerprint) do |event|
            event.environment      = parsed_alert.environment
            event.title            = parsed_alert.title
            event.query_expression = parsed_alert.full_query
          end

          set_status(parsed_alert, event)
        end

        def set_status(parsed_alert, event)
          persisted = case parsed_alert.status
                      when 'firing'
                        event.fire(parsed_alert.starts_at)
                      when 'resolved'
                        event.resolve(parsed_alert.ends_at)
                      end

          event if persisted
        end
      end
    end
  end
end
