# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  include RenderServiceResults

  before_action :authorize_read_prometheus!
  before_action :environment

  def proxy
    result = Prometheus::ProxyService.new(
      environment,
      proxy_method,
      proxy_path,
      proxy_params
    ).execute

    return continue_polling_response if result.nil?
    return error_response(result) if result[:status] == :error

    success_response(result)
  end

  private

  def query_context
    Gitlab::Prometheus::QueryVariables.call(environment)
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end

  def proxy_method
    request.method
  end

  def proxy_path
    params[:proxy_path]
  end

  def proxy_params
    substitute_query_variables(params).permit!
  end

  def substitute_query_variables(params)
    query = params[:query]
    return params unless query

    params.merge(query: query % query_context)
  end
end
