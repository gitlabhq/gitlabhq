# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrieve dashboards.
module Metrics
  module Dashboard
    class SystemDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'
      DASHBOARD_NAME = N_('Default dashboard')

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = '4685fe386c25b1a786b3be18f79bb2ee9828019003e003816284cdb634fa3e13'

      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::CustomMetricsInserter,
        STAGES::CustomMetricsDetailsInserter,
        STAGES::MetricEndpointInserter,
        STAGES::VariableEndpointInserter,
        STAGES::PanelIdsInserter,
        STAGES::Sorter,
        STAGES::AlertsInserter
      ].freeze

      class << self
        def all_dashboard_paths(_project)
          [{
            path: DASHBOARD_PATH,
            display_name: _(DASHBOARD_NAME),
            default: true,
            system_dashboard: true,
            out_of_the_box_dashboard: out_of_the_box_dashboard?
          }]
        end
      end

      private

      def dashboard_version
        DASHBOARD_VERSION
      end
    end
  end
end
