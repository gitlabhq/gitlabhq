# frozen_string_literal: true

class Projects::Environments::PrometheusApiController < Projects::ApplicationController
  before_action :authorize_read_prometheus!
  before_action :environment

  def proxy
    permitted = permit_params

    result = Prometheus::ProxyService.new(
      environment,
      request.method,
      permitted[:proxy_path],
      permitted.except(:proxy_path) # rubocop: disable CodeReuse/ActiveRecord
    ).execute

    if result.nil?
      render status: :accepted, json: {
        status: 'processing',
        message: 'Not ready yet. Try again later.'
      }
      return
    end

    if result[:status] == :success
      render status: result[:http_status], json: result[:body]
    else
      render status: result[:http_status] || :bad_request, json: {
          status: result[:status],
          message: result[:message]
        }
    end
  end

  private

  def permit_params
    params.permit([
      :proxy_path, :query, :time, :timeout, :start, :end, :step, { match: [] },
      :match_target, :metric, :limit
    ])
  end

  def environment
    @environment ||= project.environments.find(params[:id])
  end
end
