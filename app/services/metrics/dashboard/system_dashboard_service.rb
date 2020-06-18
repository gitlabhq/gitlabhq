# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrieve dashboards.
module Metrics
  module Dashboard
    class SystemDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'
      DASHBOARD_NAME = N_('Default dashboard')

      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::CustomMetricsInserter,
        STAGES::CustomMetricsDetailsInserter,
        STAGES::EndpointInserter,
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
            system_dashboard: true
          }]
        end
      end
    end
  end
end
