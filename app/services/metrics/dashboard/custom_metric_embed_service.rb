# frozen_string_literal: true

# Responsible for returning a dashboard containing specified
# custom metrics. Creates panels based on the matching metrics
# stored in the database.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class CustomMetricEmbedService < ::Metrics::Dashboard::BaseEmbedService
      extend ::Gitlab::Utils::Override
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Metrics::Dashboard::Defaults

      class << self
        # Determines whether the provided params are sufficient
        # to uniquely identify a panel composed of user-defined
        # custom metrics from the DB.
        def valid_params?(params)
          [
            params[:embedded],
            valid_dashboard?(params[:dashboard_path]),
            valid_group_title?(params[:group]),
            params[:title].present?,
            params.has_key?(:y_label)
          ].all?
        end

        private

        # A group title is valid if it is one of the limited
        # options the user can select in the UI.
        def valid_group_title?(group)
          PrometheusMetricEnums
            .custom_group_details
            .map { |_, details| details[:group_title] }
            .include?(group)
        end

        # All custom metrics are displayed on the system dashboard.
        # Nil is acceptable as we'll default to the system dashboard.
        def valid_dashboard?(dashboard)
          dashboard.nil? || ::Metrics::Dashboard::SystemDashboardService.matching_dashboard?(dashboard)
        end
      end

      # Returns a new dashboard with only the matching
      # metrics from the system dashboard, stripped of
      # group info.
      #
      # Note: This overrides the method #raw_dashboard,
      # which means the result will not be cached. This
      # is because we are inserting DB info into the
      # dashboard before post-processing. This ensures
      # we aren't acting on deleted or out-of-date metrics.
      #
      # @return [Hash]
      override :raw_dashboard
      def raw_dashboard
        panels_not_found!(identifiers) if panels.empty?

        { 'panel_groups' => [{ 'panels' => panels }] }
      end

      private

      # Generated dashboard panels for each metric which
      # matches the provided input.
      # @return [Array<Hash>]
      def panels
        strong_memoize(:panels) do
          metrics.map { |metric| panel_for_metric(metric) }
        end
      end

      # Metrics which match the provided inputs.
      # There may be multiple metrics, but they should be
      # displayed in a single panel/chart.
      # @return [ActiveRecord::AssociationRelation<PromtheusMetric>]
      def metrics
        PrometheusMetricsFinder.new(
          project: project,
          group: group_key,
          title: title,
          y_label: y_label
        ).execute
      end

      # Returns a symbol representing the group that
      # the dashboard's group title belongs to.
      # It will be one of the keys found under
      # PrometheusMetricEnums.custom_groups.
      #
      # @return [String]
      def group_key
        strong_memoize(:group_key) do
          PrometheusMetricEnums
            .group_details
            .find { |_, details| details[:group_title] == group }
            .first
            .to_s
        end
      end

      # Returns a representation of a PromtheusMetric
      # as a dashboard panel. As the panel is generated
      # on the fly, we're using default values for info
      # not represented in the DB.
      #
      # @return [Hash]
      def panel_for_metric(metric)
        {
          type: DEFAULT_PANEL_TYPE,
          weight: DEFAULT_PANEL_WEIGHT,
          title: metric.title,
          y_label: metric.y_label,
          metrics: [metric.to_metric_hash]
        }
      end
    end
  end
end
