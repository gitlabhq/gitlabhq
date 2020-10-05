# frozen_string_literal: true

# Responsible for returning a filtered project dashboard
# containing only the request-provided metrics. The result
# is then cached for future requests. Metrics are identified
# based on a combination of identifiers for now, but the ideal
# would be similar to the approach in DefaultEmbedService, but
# a single unique identifier is not currently available across
# all metric types (custom, project-defined, cluster, or system).
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class DynamicEmbedService < ::Metrics::Dashboard::BaseEmbedService
      include Gitlab::Utils::StrongMemoize

      class << self
        # Determines whether the provided params are sufficient
        # to uniquely identify a panel from a yml-defined dashboard.
        #
        # See https://docs.gitlab.com/ee/operations/metrics/dashboards/index.html
        # for additional info on defining custom dashboards.
        def valid_params?(params)
          [
            embedded?(params[:embedded]),
            params[:group].present?,
            params[:title].present?,
            params[:y_label]
          ].all?
        end
      end

      # Returns a new dashboard with only the matching
      # metrics from the system dashboard, stripped of groups.
      # @return [Hash]
      def get_raw_dashboard
        not_found! if panels.empty?

        { 'panel_groups' => [{ 'panels' => panels }] }
      end

      private

      def panels
        strong_memoize(:panels) do
          not_found! unless base_dashboard
          not_found! unless groups = base_dashboard['panel_groups']
          not_found! unless matching_group = find_group(groups)
          not_found! unless all_panels = matching_group['panels']

          find_panels(all_panels)
        end
      end

      def base_dashboard
        strong_memoize(:base_dashboard) do
          Gitlab::Metrics::Dashboard::Finder.find_raw(project, dashboard_path: dashboard_path)
        end
      end

      def find_group(groups)
        groups.find do |candidate_group|
          candidate_group['group'] == group
        end
      end

      def find_panels(all_panels)
        all_panels.select do |panel|
          panel['title'] == title && panel['y_label'] == y_label
        end
      end

      def not_found!
        panels_not_found!(identifiers)
      end
    end
  end
end
