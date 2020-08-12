# frozen_string_literal: true

module Metrics
  module Dashboard
    class PodDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/pod_metrics.yml'
      DASHBOARD_NAME = N_('K8s pod health')

      # SHA256 hash of dashboard content
      DASHBOARD_VERSION = '3a91b32f91b2dd3d90275333c0ea3630b3f3f37c4296ede5b5eef59bf523d66b'

      SEQUENCE = [
        STAGES::MetricEndpointInserter,
        STAGES::VariableEndpointInserter,
        STAGES::PanelIdsInserter
      ].freeze

      class << self
        def all_dashboard_paths(_project)
          [{
            path: DASHBOARD_PATH,
            display_name: _(DASHBOARD_NAME),
            default: false,
            system_dashboard: false,
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
