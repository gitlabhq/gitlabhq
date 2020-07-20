# frozen_string_literal: true

module Metrics
  module Dashboard
    class PodDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/pod_metrics.yml'
      DASHBOARD_NAME = 'Pod Health'

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = 'f12f641d2575d5dcb69e2c633ff5231dbd879ad35020567d8fc4e1090bfdb4b4'

      private

      def dashboard_version
        DASHBOARD_VERSION
      end
    end
  end
end
