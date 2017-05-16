require 'prometheus/client/formats/text'

class HealthController < ActionController::Base
  protect_from_forgery with: :exception
  include RequiresHealthToken

  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::RedisCheck,
    Gitlab::HealthChecks::FsShardsCheck
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
    response = health_metrics_text + "\n"

    if Gitlab::Metrics.prometheus_metrics_enabled?
      response += Prometheus::Client::Formats::Text.marshal_multiprocess(ENV['prometheus_multiproc_dir'])
    end

    render text: response, content_type: 'text/plain; version=0.0.4'
  end

  private

  def health_metrics_text
    results = CHECKS.flat_map(&:metrics)

    types = results.map(&:name)
              .uniq
              .map { |metric_name| "# TYPE #{metric_name} gauge" }
    metrics = results.map(&method(:metric_to_prom_line))
    types.concat(metrics).join("\n")
  end

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
