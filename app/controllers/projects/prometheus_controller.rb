class Projects::PrometheusController < Projects::ApplicationController
  before_action :authorize_read_project!
  before_action :require_prometheus_metrics!

  def active_metrics
    respond_to do |format|
      format.json do
        matched_metrics = prometheus_service.matched_metrics || {}

        if matched_metrics.any?
          render json: matched_metrics
        else
          head :no_content
        end
      end
    end
  end

  private

  rescue_from(ActionController::UnknownFormat) do
    render_404
  end

  def prometheus_service
    @prometheus_service ||= project.monitoring_services.reorder(nil).find_by(active: true, type: PrometheusService.name)
  end

  def require_prometheus_metrics!
    render_404 unless prometheus_service.present?
  end
end
