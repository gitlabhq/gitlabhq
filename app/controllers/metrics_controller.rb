class MetricsController < ActionController::Base
  include RequiresHealthToken

  protect_from_forgery with: :exception

  before_action :validate_prometheus_metrics

  def metrics
    response = "#{metrics_service.health_metrics_text}\n#{metrics_service.prometheus_metrics_text}"

    render text: response, content_type: 'text/plain; version=0.0.4'
  end

  private

  def metrics_service
    @metrics_service ||= MetricsService.new
  end

  def validate_prometheus_metrics
    render_404 unless Gitlab::Metrics.prometheus_metrics_enabled?
  end
end
