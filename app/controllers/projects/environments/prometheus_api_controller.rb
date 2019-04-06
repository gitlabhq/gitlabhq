# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  before_action :authorize_read_prometheus!
  before_action :environment

  def proxy
    result = Prometheus::ProxyService.new(
      environment,
      request.method,
      params[:proxy_path],
      params.permit!
    ).execute

    if result.nil?
      return render status: :accepted, json: {
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

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end
