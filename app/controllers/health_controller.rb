class HealthController < ActionController::Base
  protect_from_forgery with: :exception
  include RequiresHealthToken

  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::RedisCheck,
    Gitlab::HealthChecks::FsShardsCheck,
  ].freeze

  def readiness
    results = CHECKS.map { |check| [check.name, check.readiness] }

    render_check_results(results)
  end

  def liveness
    results = CHECKS.map { |check| [check.name, check.liveness] }

    render_check_results(results)
  end

  def metrics
    results = CHECKS.flat_map(&:metrics)

    response = results.map(&method(:metric_to_prom_line)).join("\n")

    render text: response, content_type: 'text/plain; version=0.0.4'
  end

  private

  def metric_to_prom_line(metric)
    labels = metric.labels&.map { |key, value| "#{key}=\"#{value}\"" }&.join(',') || ''
    if labels.empty?
      "#{metric.name} #{metric.value}"
    else
      "#{metric.name}{#{labels}} #{metric.value}"
    end
  end

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
