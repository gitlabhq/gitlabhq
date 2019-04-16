# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    class ProjectMetricsInserter
      DEFAULT_PANEL_TYPE = 'area-chart'

      class << self
        # Inserts project-specific metrics into the dashboard config.
        # If there are no project-specific metrics, this will have no effect.
        def transform!(dashboard, project)
          project.prometheus_metrics.each do |project_metric|
            group = find_or_create(:panel_group, dashboard[:panel_groups], project_metric)
            panel = find_or_create(:panel, group[:panels], project_metric)
            find_or_create(:metric, panel[:metrics], project_metric)
          end
        end

        # Looks for an instance of the named resource corresponding to the provided
        # metric object. If unavailable, inserts one.
        # @param name [Symbol, String] One of :panel_group, :panel, or :metric
        # @param existing_resources [Array<Hash>]
        # @param metric [PrometheusMetric]
        def find_or_create(name, existing_resources, metric)
          target = self.send("find_#{name}", existing_resources, metric)
          return target if target

          target = self.send("new_#{name}", metric)
          existing_resources << target

          target
        end

        def find_panel_group(panel_groups, metric)
          panel_groups.find { |group| group[:group] == metric.group_title }
        end

        def find_panel(panels, metric)
          panel_identifiers = [DEFAULT_PANEL_TYPE, metric.title, metric.y_label]
          target_panel = panels.find { |panel| panel.values_at(:type, :title, :y_label) == panel_identifiers }
        end

        def find_metric(metrics, metric)
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
          metric.queries.first.merge(metric_id: metric.id)
        end
      end
    end
  end
end
