# frozen_string_literal: true

# Fetches the self monitoring metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrieve dashboards.
module Metrics
  module Dashboard
    class SelfMonitoringDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/self_monitoring_default.yml'
      DASHBOARD_NAME = N_('Default dashboard')

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = '1dff3e3cb76e73c8e368823c98b34c61aec0d141978450dea195a3b3dc2415d6'

      SEQUENCE = [
        STAGES::CustomMetricsInserter,
        STAGES::MetricEndpointInserter,
        STAGES::VariableEndpointInserter,
        STAGES::PanelIdsInserter,
        STAGES::Sorter
      ].freeze

      class << self
        def valid_params?(params)
          matching_dashboard?(params[:dashboard_path]) || self_monitoring_project?(params)
        end

        def all_dashboard_paths(_project)
          [{
            path: DASHBOARD_PATH,
            display_name: _(DASHBOARD_NAME),
            default: true,
            system_dashboard: false,
            out_of_the_box_dashboard: out_of_the_box_dashboard?
          }]
        end

        def self_monitoring_project?(params)
          params[:dashboard_path].nil? && params[:environment]&.project&.self_monitoring?
        end
      end

      private

      def dashboard_version
        DASHBOARD_VERSION
      end
    end
  end
end
