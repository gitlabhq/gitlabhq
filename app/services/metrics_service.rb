require 'prometheus/client/formats/text'

class MetricsService
  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::RedisCheck,
    Gitlab::HealthChecks::FsShardsCheck
  ].freeze

  def prometheus_metrics_text
    Prometheus::Client::Formats::Text.marshal_multiprocess(multiprocess_metrics_path)
  end

  def health_metrics_text
    results = CHECKS.flat_map(&:metrics)

    types = results.map(&:name).uniq.map { |metric_name| "# TYPE #{metric_name} gauge" }
    metrics = results.map(&method(:metric_to_prom_line))

    types.concat(metrics).join("\n")
  end

  private

  def multiprocess_metrics_path
    Rails.root.join(ENV['prometheus_multiproc_dir'])
  end

  def metric_to_prom_line(metric)
    labels = metric.labels&.map { |key, value| "#{key}=\"#{value}\"" }&.join(',') || ''

    if labels.empty?
      "#{metric.name} #{metric.value}"
    else
      "#{metric.name}{#{labels}} #{metric.value}"
    end
  end
end
