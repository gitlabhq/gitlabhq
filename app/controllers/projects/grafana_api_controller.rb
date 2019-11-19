# frozen_string_literal: true

class Projects::GrafanaApiController < Projects::ApplicationController
  include RenderServiceResults
  include MetricsDashboard

  def proxy
    result = ::Grafana::ProxyService.new(
      project,
      params[:datasource_id],
      params[:proxy_path],
      query_params.to_h
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
    params.permit(:query, :start, :end, :step)
  end
end
