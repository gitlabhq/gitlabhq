class Projects::PrometheusController < Projects::ApplicationController
  before_action :authorize_read_project!

  def active_metrics
    return render_404 unless has_prometheus_metrics?
    matched_metrics = prometheus_service.reactive_query(Gitlab::Prometheus::Queries::MatchedMetricsQuery.name, &:itself)

    if matched_metrics
      render json: matched_metrics, status: :ok
    else
      head :no_content
    end
  end

  def prometheus_service
    project.monitoring_service
  end

  def has_prometheus_metrics?
    prometheus_service&.respond_to?(:reactive_query)
  end
end
