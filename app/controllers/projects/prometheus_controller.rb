class Projects::PrometheusController < Projects::ApplicationController
  before_action :authorize_read_project!
  before_action :require_prometheus_metrics!

  def active_metrics
    matched_metrics = prometheus_service.reactive_query(Gitlab::Prometheus::Queries::MatchedMetricsQuery.name, &:itself) || {}

    respond_to do |format|
      format.json do
        if matched_metrics.any?
          render json: matched_metrics
        else
          head :no_content
        end
      end
    end
  end

  private

  rescue_from(ActionController::UnknownFormat) do |e|
    render_404
  end

  def prometheus_service
    project.monitoring_service
  end

  def has_prometheus_metrics?
    prometheus_service&.respond_to?(:reactive_query)
  end

  def require_prometheus_metrics!
    render_404 unless has_prometheus_metrics?
  end
end
