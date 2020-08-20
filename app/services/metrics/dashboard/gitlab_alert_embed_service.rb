# frozen_string_literal: true

# Responsible for returning an embed containing the specified
# metrics chart for an alert. Creates panels based on the
# matching metric stored in the database.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrieve dashboards.
module Metrics
  module Dashboard
    class GitlabAlertEmbedService < ::Metrics::Dashboard::BaseEmbedService
      include Gitlab::Metrics::Dashboard::Defaults
      include Gitlab::Utils::StrongMemoize

      SEQUENCE = [
        STAGES::MetricEndpointInserter,
        STAGES::PanelIdsInserter
      ].freeze

      class << self
        # Determines whether the provided params are sufficient
        # to uniquely identify a panel composed of user-defined
        # custom metrics from the DB.
        def valid_params?(params)
          [
            embedded?(params[:embedded]),
            params[:prometheus_alert_id].is_a?(Integer)
          ].all?
        end
      end

      def raw_dashboard
        panels_not_found!(alert_id: alert_id) unless alert && prometheus_metric

        { 'panel_groups' => [{ 'panels' => [panel] }] }
      end

      private

      def allowed?
        Ability.allowed?(current_user, :read_prometheus_alerts, project)
      end

      def alert_id
        params[:prometheus_alert_id]
      end

      def alert
        strong_memoize(:alert) do
          Projects::Prometheus::AlertsFinder.new(id: alert_id).execute.first
        end
      end

      def process_params
        params.merge(environment: alert.environment)
      end

      def prometheus_metric
        strong_memoize(:prometheus_metric) do
          PrometheusMetricsFinder.new(id: alert.prometheus_metric_id).execute.first
        end
      end

      def panel
        {
          title: prometheus_metric.title,
          y_label: prometheus_metric.y_label,
          metrics: [prometheus_metric.to_metric_hash],
          type: DEFAULT_PANEL_TYPE
        }
      end

      def sequence
        SEQUENCE
      end
    end
  end
end
