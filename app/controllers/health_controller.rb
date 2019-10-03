# frozen_string_literal: true

class HealthController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  include RequiresWhitelistedMonitoringClient

  def readiness
    results = checks.flat_map(&:readiness)
    success = results.all?(&:success)

    # disable static error pages at the gitlab-workhorse level, we want to see this error response even in production
    headers["X-GitLab-Custom-Error"] = 1 unless success

    response = results.map { |result| [result.name, result.payload] }.to_h
    render json: response, status: success ? :ok : :service_unavailable
  end

  def liveness
    render json: { status: 'ok' }, status: :ok
  end

  private

  def checks
    ::Gitlab::HealthChecks::CHECKS
  end
end
