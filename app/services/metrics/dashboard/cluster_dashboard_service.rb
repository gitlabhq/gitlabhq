# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ClusterDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/cluster_metrics.yml'
      DASHBOARD_NAME = 'Cluster'

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = 'e1a4f8cc2c044cf32273af2cd775eb484729baac0995db687d81d92686bf588e'

      SEQUENCE = [
        STAGES::ClusterEndpointInserter,
        STAGES::PanelIdsInserter
      ].freeze

      class << self
        def valid_params?(params)
          # support selecting this service by cluster id via .find
          # Use super to support selecting this service by dashboard_path via .find_raw
          (params[:cluster].present? && params[:embedded] != 'true') || super
        end
      end

      # Permissions are handled at the controller level
      def allowed?
        true
      end

      private

      def dashboard_version
        DASHBOARD_VERSION
      end
    end
  end
end
