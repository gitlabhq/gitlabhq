class PrometheusMetricEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :title

  expose :group
  expose :group_title
  expose :unit

  expose :edit_path do |prometheus_metric|
    edit_project_prometheus_metric_path(prometheus_metric.project, prometheus_metric)
  end
end
