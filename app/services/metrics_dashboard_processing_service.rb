# frozen_string_literal: true

class MetricsDashboardProcessingService
  DEFAULT_PANEL_TYPE = 'area-chart'

  def initialize(dashboard, project)
    @dashboard = dashboard.deep_transform_keys(&:to_sym)
    @project = project
  end

  def process
    insert_persisted_metrics!
    insert_metric_ids!
    @dashboard.to_json
  end

  private

  # Inserts project-specific metrics into the dashboard config.
  # If there are no project-specific metrics, this will have no effect.
  def insert_persisted_metrics!
    @project.prometheus_metrics.each do |persisted_metric|
      group = find_or_create_group(@dashboard[:panel_groups], persisted_metric)
      panel = find_or_create_panel(group[:panels], persisted_metric)
      find_or_create_metric(panel[:metrics], persisted_metric)
    end
  end

  # For each metric in the dashboard config, attempts to find a corresponding
  # persisted record. If found, includes the record id in the config.
  def insert_metric_ids!
    @dashboard[:panel_groups].each do |group|
      group[:panels].each do |panel|
        panel[:metrics].each do |metric|
          metric_record = common_metrics.find {|m| m.identifier == metric[:id] }
          metric[:metric_id] = metric_record.id if metric_record
        end
      end
    end
  end

  def common_metrics
    @common_metrics ||= ::PrometheusMetric.common
  end

  def find_or_create_group(panel_groups, metric)
    target_group = panel_groups.find { |group| group[:group] == metric.group_title }

    unless target_group
      target_group = {
        group: metric.group_title,
        priority: metric.priority,
        panels: []
      }
      panel_groups << target_group
    end

    target_group
  end

  def find_or_create_panel(panels, metric)
    panel_identifiers = [DEFAULT_PANEL_TYPE, metric.title, metric.y_label]
    target_panel = panels.find { |panel| panel.values_at(:type, :title, :y_label) == panel_identifiers }

    unless target_panel
      target_panel = {
        type: DEFAULT_PANEL_TYPE,
        title: metric.title,
        y_label: metric.y_label,
        metrics: []
      }
      panels << target_panel
    end

    target_panel
  end

  def find_or_create_metric(metrics, metric)
    target_metric = metrics.find { |m| m[:id] == metric.identifier }

    unless target_metric
      target_metric = metric.queries.first.merge(metric_id: metric.id)
      metrics << target_metric
    end

    target_metric
  end
end
