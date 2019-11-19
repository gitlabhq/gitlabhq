# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class ProjectMetricsInserter < BaseStage
          # Inserts project-specific metrics into the dashboard
          # config. If there are no project-specific metrics,
          # this will have no effect.
          def transform!
            PrometheusMetricsFinder.new(project: project).execute.each do |project_metric|
              group = find_or_create_panel_group(dashboard[:panel_groups], project_metric)
              panel = find_or_create_panel(group[:panels], project_metric)
              find_or_create_metric(panel[:metrics], project_metric)
            end
          end

          private

          # Looks for a panel_group corresponding to the
          # provided metric object. If unavailable, inserts one.
          # @param panel_groups [Array<Hash>]
          # @param metric [PrometheusMetric]
          def find_or_create_panel_group(panel_groups, metric)
            panel_group = find_panel_group(panel_groups, metric)
            return panel_group if panel_group

            panel_group = new_panel_group(metric)
            panel_groups << panel_group

            panel_group
          end

          # Looks for a panel corresponding to the provided
          # metric object. If unavailable, inserts one.
          # @param panels [Array<Hash>]
          # @param metric [PrometheusMetric]
          def find_or_create_panel(panels, metric)
            panel = find_panel(panels, metric)
            return panel if panel

            panel = new_panel(metric)
            panels << panel

            panel
          end

          # Looks for a metric corresponding to the provided
          # metric object. If unavailable, inserts one.
          # @param metrics [Array<Hash>]
          # @param metric [PrometheusMetric]
          def find_or_create_metric(metrics, metric)
            target_metric = find_metric(metrics, metric)
            return target_metric if target_metric

            target_metric = new_metric(metric)
            metrics << target_metric

            target_metric
          end

          def find_panel_group(panel_groups, metric)
            return unless panel_groups

            panel_groups.find { |group| group[:group] == metric.group_title }
          end

          def find_panel(panels, metric)
            return unless panels

            panel_identifiers = [DEFAULT_PANEL_TYPE, metric.title, metric.y_label]
            panels.find { |panel| panel.values_at(:type, :title, :y_label) == panel_identifiers }
          end

          def find_metric(metrics, metric)
            return unless metrics

            metrics.find { |m| m[:id] == metric.identifier }
          end

          def new_panel_group(metric)
            {
              group: metric.group_title,
              priority: metric.priority,
              panels: []
            }
          end

          def new_panel(metric)
            {
              type: DEFAULT_PANEL_TYPE,
              title: metric.title,
              y_label: metric.y_label,
              metrics: []
            }
          end

          def new_metric(metric)
            metric.to_metric_hash
          end
        end
      end
    end
  end
end
