# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  include RenderServiceResults

  before_action :authorize_read_prometheus!
  before_action :environment

  def proxy
    variable_substitution_result =
      variable_substitution_service.new(environment, permit_params).execute

    if variable_substitution_result[:status] == :error
      return error_response(variable_substitution_result)
    end

    prometheus_result = Prometheus::ProxyService.new(
      environment,
      proxy_method,
      proxy_path,
      variable_substitution_result[:params]
    ).execute

    return continue_polling_response if prometheus_result.nil?
    return error_response(prometheus_result) if prometheus_result[:status] == :error

    success_response(prometheus_result)
  end

  private

  def variable_substitution_service
    Prometheus::ProxyVariableSubstitutionService
  end

  def permit_params
    params.permit!
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
end
