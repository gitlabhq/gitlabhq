# frozen_string_literal: true

class Projects::GrafanaApiController < Projects::ApplicationController
  include RenderServiceResults
  include MetricsDashboard

  before_action :authorize_read_grafana!, only: :proxy

  feature_category :metrics
  urgency :low

  def proxy
    return not_found if Feature.enabled?(:remove_monitor_metrics)

    result = ::Grafana::ProxyService.new(
      project,
      params[:datasource_id],
      params[:proxy_path],
      prometheus_params
    ).execute

    return continue_polling_response if result.nil?
    return error_response(result) if result[:status] == :error

    success_response(result)
  end

  private

  def metrics_dashboard_params
    params.permit(:embedded, :grafana_url)
  end

  def query_params
    params.permit(:query, :start_time, :end_time, :step)
  end

  def prometheus_params
    query_params.to_h
      .except(:start_time, :end_time)
      .merge(
        start: query_params[:start_time],
        end: query_params[:end_time]
      )
  end
end
