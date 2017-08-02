class MetricsController < ActionController::Base
  include RequiresWhitelistedMonitoringClient

  protect_from_forgery with: :exception

  before_action :validate_prometheus_metrics

  def index
    render text: metrics_service.metrics_text, content_type: 'text/plain; version=0.0.4'
  end

  private

  def metrics_service
    @metrics_service ||= MetricsService.new
  end

  def validate_prometheus_metrics
    render_404 unless Gitlab::Metrics.prometheus_metrics_enabled?
  end
end
