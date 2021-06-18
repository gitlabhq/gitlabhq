# frozen_string_literal: true

module Metrics::Dashboard::PrometheusApiProxy
  extend ActiveSupport::Concern
  include RenderServiceResults

  included do
    before_action :authorize_read_prometheus!, only: [:prometheus_proxy]
  end

  def prometheus_proxy
    variable_substitution_result =
      proxy_variable_substitution_service.new(proxyable, permit_params).execute

    if variable_substitution_result[:status] == :error
      return error_response(variable_substitution_result)
    end

    prometheus_result = ::Prometheus::ProxyService.new(
      proxyable,
      proxy_method,
      proxy_path,
      variable_substitution_result[:params]
    ).execute

    return continue_polling_response if prometheus_result.nil?
    return error_response(prometheus_result) if prometheus_result[:status] == :error

    success_response(prometheus_result)
  end

  private

  def proxyable
    raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
  end

  def proxy_variable_substitution_service
    raise NotImplementedError, "#{self.class} must implement method: #{__callee__}"
  end

  def permit_params
    params.permit!
  end

  def proxy_method
    request.method
  end

  def proxy_path
    params[:proxy_path]
  end
end
