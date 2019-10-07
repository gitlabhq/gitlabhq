# frozen_string_literal: true

class HealthController < ActionController::Base
  protect_from_forgery with: :exception, prepend: true
  include RequiresWhitelistedMonitoringClient

  def readiness
    render_probe(::Gitlab::HealthChecks::Probes::Readiness)
  end

  def liveness
    render_probe(::Gitlab::HealthChecks::Probes::Liveness)
  end

  private

  def render_probe(probe_class)
    result = probe_class.new.execute

    # disable static error pages at the gitlab-workhorse level, we want to see this error response even in production
    headers["X-GitLab-Custom-Error"] = 1 unless result.success?

    render json: result.json, status: result.http_status
  end
end
