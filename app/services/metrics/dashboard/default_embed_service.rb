# frozen_string_literal: true

# Responsible for returning a filtered system dashboard
# containing only the default embedded metrics. In future,
# this class may be updated to support filtering to
# alternate metrics/panels.
#
# Why isn't this filtering in a processing stage? By filtering
# here, we ensure the dynamically-determined dashboard is cached.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class DefaultEmbedService < ::Metrics::Dashboard::BaseService
      # For the default filtering for embedded metrics,
      # uses the 'id' key in dashboard-yml definition for
      # identification.
      DEFAULT_EMBEDDED_METRICS_IDENTIFIERS = %w(
        system_metrics_kubernetes_container_memory_total
        system_metrics_kubernetes_container_cores_total
      ).freeze

      # Returns a new dashboard with only the matching
      # metrics from the system dashboard, stripped of groups.
      # @return [Hash]
      def raw_dashboard
        panels = panel_groups.each_with_object([]) do |group, panels|
          matched_panels = group['panels'].select { |panel| matching_panel?(panel) }

          panels.concat(matched_panels)
        end

        { 'panel_groups' => [{ 'panels' => panels }] }
      end

      def cache_key
        "dynamic_metrics_dashboard_#{metric_identifiers.join('_')}"
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
    end
  end
end
