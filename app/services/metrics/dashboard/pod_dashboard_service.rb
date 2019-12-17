# frozen_string_literal: true

module Metrics
  module Dashboard
    class PodDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/pod_metrics.yml'
      DASHBOARD_NAME = 'Pod Health'
    end
  end
end
