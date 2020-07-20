# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ClusterDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/cluster_metrics.yml'
      DASHBOARD_NAME = 'Cluster'

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = '9349afc1d96329c08ab478ea0b77db94ee5cc2549b8c754fba67a7f424666b22'

      SEQUENCE = [
        STAGES::ClusterEndpointInserter,
        STAGES::PanelIdsInserter,
        STAGES::Sorter
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
