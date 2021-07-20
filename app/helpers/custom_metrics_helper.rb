# frozen_string_literal: true

module CustomMetricsHelper
  def custom_metrics_data(project, metric)
    {
      'custom-metrics-path' => url_for([project, metric]),
      'metric-persisted' => metric.persisted?.to_s,
      'edit-project-service-path' => edit_project_service_path(project, ::Integrations::Prometheus),
      'validate-query-path' => validate_query_project_prometheus_metrics_path(project),
      'title' => metric.title.to_s,
      'query' => metric.query.to_s,
      'y-label' => metric.y_label.to_s,
      'unit' => metric.unit.to_s,
      'group' => metric.group.to_s,
      'legend' => metric.legend.to_s
    }
  end
end
