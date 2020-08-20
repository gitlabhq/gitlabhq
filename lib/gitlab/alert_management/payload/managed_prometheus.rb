# frozen_string_literal: true

# Attribute mapping for alerts via prometheus alerting integration,
# and for which payload includes gitlab-controlled attributes.
module Gitlab
  module AlertManagement
    module Payload
      class ManagedPrometheus < ::Gitlab::AlertManagement::Payload::Prometheus
        attribute :gitlab_prometheus_alert_id,
                  paths: %w(labels gitlab_prometheus_alert_id),
                  type: :integer
        attribute :metric_id,
                  paths: %w(labels gitlab_alert_id),
                  type: :integer

        def gitlab_alert
          strong_memoize(:gitlab_alert) do
            next unless metric_id || gitlab_prometheus_alert_id

            alerts = Projects::Prometheus::AlertsFinder
              .new(project: project, metric: metric_id, id: gitlab_prometheus_alert_id)
              .execute

            next if alerts.blank? || alerts.size > 1

            alerts.first
          end
        end

        def full_query
          gitlab_alert&.full_query || super
        end

        def environment
          gitlab_alert&.environment || super
        end

        def metrics_dashboard_url
          return unless gitlab_alert

          metrics_dashboard_project_prometheus_alert_url(
            project,
            gitlab_alert.prometheus_metric_id,
            environment_id: environment.id,
            embedded: true,
            **alert_embed_window_params
          )
        end

        private

        def plain_gitlab_fingerprint
          [metric_id, starts_at_raw].join('/')
        end
      end
    end
  end
end
