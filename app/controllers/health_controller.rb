# frozen_string_literal: true

class HealthController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  include RequiresWhitelistedMonitoringClient

  CHECKS = [
    Gitlab::HealthChecks::MasterCheck
  ].freeze

  ALL_CHECKS = [
    *CHECKS,
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::Redis::RedisCheck,
    Gitlab::HealthChecks::Redis::CacheCheck,
    Gitlab::HealthChecks::Redis::QueuesCheck,
    Gitlab::HealthChecks::Redis::SharedStateCheck,
    Gitlab::HealthChecks::GitalyCheck
  ].freeze

  def readiness
    # readiness check is a collection of application-level checks
    # and optionally all service checks
    render_checks(params[:all] ? ALL_CHECKS : CHECKS)
  end

  def liveness
    # liveness check is a collection without additional checks
    render_checks
  end

  private

  def render_checks(checks = [])
    result = Gitlab::HealthChecks::Probes::Collection
      .new(*checks)
      .execute

    # disable static error pages at the gitlab-workhorse level, we want to see this error response even in production
    headers["X-GitLab-Custom-Error"] = 1 unless result.success?

    render json: result.json, status: result.http_status
  end
end
