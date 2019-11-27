# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrieve dashboards.
module Metrics
  module Dashboard
    class SystemDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'
      DASHBOARD_NAME = 'Default'

      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::ProjectMetricsInserter,
        STAGES::EndpointInserter,
        STAGES::Sorter
      ].freeze

      class << self
        def all_dashboard_paths(_project)
          [{
            path: DASHBOARD_PATH,
            display_name: DASHBOARD_NAME,
            default: true,
            system_dashboard: true
          }]
        end
      end
    end
  end
end

Metrics::Dashboard::SystemDashboardService.prepend_if_ee('EE::Metrics::Dashboard::SystemDashboardService')
