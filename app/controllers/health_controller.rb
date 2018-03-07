class HealthController < ActionController::Base
  protect_from_forgery with: :exception, except: :storage_check
  include RequiresWhitelistedMonitoringClient

  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::Redis::RedisCheck,
    Gitlab::HealthChecks::Redis::CacheCheck,
    Gitlab::HealthChecks::Redis::QueuesCheck,
    Gitlab::HealthChecks::Redis::SharedStateCheck,
    Gitlab::HealthChecks::FsShardsCheck,
    Gitlab::HealthChecks::GitalyCheck
  ].freeze

  def readiness
    results = CHECKS.map { |check| [check.name, check.readiness] }

    render_check_results(results)
  end

  def liveness
    results = CHECKS.map { |check| [check.name, check.liveness] }

    render_check_results(results)
  end

  def storage_check
    results = Gitlab::Git::Storage::Checker.check_all

    render json: {
             check_interval: Gitlab::CurrentSettings.current_application_settings.circuitbreaker_check_interval,
             results: results
           }
  end

  private

  def render_check_results(results)
    flattened = results.flat_map do |name, result|
      if result.is_a?(Gitlab::HealthChecks::Result)
        [[name, result]]
      else
        result.map { |r| [name, r] }
      end
    end
    success = flattened.all? { |name, r| r.success }

    response = flattened.map do |name, r|
      info = { status: r.success ? 'ok' : 'failed' }
      info['message'] = r.message if r.message
      info[:labels] = r.labels if r.labels
      [name, info]
    end
    render json: response.to_h, status: success ? :ok : :service_unavailable
  end
end
