# frozen_string_literal: true

require 'prometheus/client/formats/text'

class MetricsService
  def prometheus_metrics_text
    ::Prometheus::Client::Formats::Text.marshal_multiprocess(multiprocess_metrics_path)
  end

  def metrics_text
    prometheus_metrics_text
  end

  private

  def multiprocess_metrics_path
    ::Prometheus::Client.configuration.multiprocess_files_dir
  end
end
