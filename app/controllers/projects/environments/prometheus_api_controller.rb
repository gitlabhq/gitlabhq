# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  before_action :authorize_read_prometheus!
  before_action :environment

  def proxy
    result = Prometheus::ProxyService.new(
      environment,
      proxy_method,
      proxy_path,
      proxy_params
    ).execute

    if result.nil?
      return render status: :no_content, json: {
        status: _('processing'),
        message: _('Not ready yet. Try again later.')
      }
    end

    if result[:status] == :success
      render status: result[:http_status], json: result[:body]
    else
      render(
        status: result[:http_status] || :bad_request,
        json: { status: result[:status], message: result[:message] }
      )
    end
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
