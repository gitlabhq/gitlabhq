# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  include Metrics::Dashboard::PrometheusApiProxy

  before_action :proxyable

  feature_category :metrics

  private

  def proxyable
    @proxyable ||= project.environments.find(params[:id])
  end

  def proxy_variable_substitution_service
    ::Prometheus::ProxyVariableSubstitutionService
  end
end
