class MetricsController < ActionController::Base
  include RequiresWhitelistedMonitoringClient

  protect_from_forgery with: :exception

  def index
    response = if Gitlab::Metrics.prometheus_metrics_enabled?
                 metrics_service.metrics_text
               else
                 help_page = help_page_url('administration/monitoring/prometheus/gitlab_metrics',
                                           anchor: 'gitlab-prometheus-metrics'
                                          )
                 "# Metrics are disabled, see: #{help_page}\n"
               end

    render text: response, content_type: 'text/plain; version=0.0.4'
  end

  private

  def metrics_service
    @metrics_service ||= MetricsService.new
  end
end
