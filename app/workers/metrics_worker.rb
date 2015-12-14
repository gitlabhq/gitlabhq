class MetricsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :metrics

  def perform(metrics)
    prepared = prepare_metrics(metrics)

    Gitlab::Metrics.pool.with do |connection|
      connection.write_points(prepared)
    end
  end

  def prepare_metrics(metrics)
    metrics.map do |hash|
      new_hash = hash.symbolize_keys

      new_hash[:tags].each do |key, value|
        if value.blank?
          new_hash[:tags].delete(key)
        else
          new_hash[:tags][key] = escape_value(value)
        end
      end

      new_hash
    end
  end

  def escape_value(value)
    value.to_s.gsub('=', '\\=')
  end
end
