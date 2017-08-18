require 'prometheus/client/formats/text'

class MetricsService
  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::Redis::RedisCheck,
    Gitlab::HealthChecks::Redis::CacheCheck,
    Gitlab::HealthChecks::Redis::QueuesCheck,
    Gitlab::HealthChecks::Redis::SharedStateCheck,
    Gitlab::HealthChecks::FsShardsCheck
  ].freeze

  def prometheus_metrics_text
    Prometheus::Client::Formats::Text.marshal_multiprocess(multiprocess_metrics_path)
  end

  def health_metrics_text
    metrics = CHECKS.flat_map(&:metrics)

    formatter.marshal(metrics)
  end

  def metrics_text
    "#{health_metrics_text}#{prometheus_metrics_text}"
  end

  private

  def formatter
    @formatter ||= Gitlab::HealthChecks::PrometheusTextFormat.new
  end

  def multiprocess_metrics_path
    ::Prometheus::Client.configuration.multiprocess_files_dir
  end
end
