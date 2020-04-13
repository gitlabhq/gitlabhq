# frozen_string_literal: true

require 'set'

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class AlertsInserter < BaseStage
          include ::Gitlab::Utils::StrongMemoize

          def transform!
            return if metrics_with_alerts.empty?

            for_metrics do |metric|
              next unless metrics_with_alerts.include?(metric[:metric_id])

              metric[:alert_path] = alert_path(metric[:metric_id], project, params[:environment])
            end
          end

          private

          def metrics_with_alerts
            strong_memoize(:metrics_with_alerts) do
              alerts = ::Projects::Prometheus::AlertsFinder
                .new(project: project, environment: params[:environment])
                .execute

              Set.new(alerts.map(&:prometheus_metric_id))
            end
          end

          def alert_path(metric_id, project, environment)
            ::Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, metric_id, environment_id: environment.id, format: :json)
          end
        end
      end
    end
  end
end
