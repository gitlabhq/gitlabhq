# frozen_string_literal: true

# Responsible for returning a filtered system dashboard
# containing only the default embedded metrics. This class
# operates by selecting metrics directly from the system
# dashboard.
#
# Why isn't this filtering in a processing stage? By filtering
# here, we ensure the dynamically-determined dashboard is cached.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class DefaultEmbedService < ::Metrics::Dashboard::BaseEmbedService
      # For the default filtering for embedded metrics,
      # uses the 'id' key in dashboard-yml definition for
      # identification.
      DEFAULT_EMBEDDED_METRICS_IDENTIFIERS = %w(
        system_metrics_kubernetes_container_memory_total
        system_metrics_kubernetes_container_cores_total
      ).freeze

      class << self
        def valid_params?(params)
          embedded?(params[:embedded])
        end
      end

      # Returns a new dashboard with only the matching
      # metrics from the system dashboard, stripped of groups.
      # @return [Hash]
      def get_raw_dashboard
        panels = panel_groups.each_with_object([]) do |group, panels|
          matched_panels = group['panels'].select { |panel| matching_panel?(panel) }

          panels.concat(matched_panels)
        end

        { 'panel_groups' => [{ 'panels' => panels }] }
      end

      private

      # Returns an array of the panels groups on the
      # system dashboard
      def panel_groups
        ::Metrics::Dashboard::SystemDashboardService
          .new(project, nil)
          .raw_dashboard['panel_groups']
      end

      # Identifies a panel as "matching" if any metric ids in
      # the panel is in the list of identifiers to collect.
      def matching_panel?(panel)
        panel['metrics'].any? do |metric|
          metric_identifiers.include?(metric['id'])
        end
      end

      def metric_identifiers
        DEFAULT_EMBEDDED_METRICS_IDENTIFIERS
      end

      def identifiers
        metric_identifiers.join('|')
      end
    end
  end
end
