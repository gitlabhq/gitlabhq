# frozen_string_literal: true

module Gitlab
  module Metrics
    module Labkit
      extend ActiveSupport::Concern

      class_methods do
        def client
          ::Labkit::Metrics::Client
        end

        def null_metric
          ::Labkit::Metrics::Null.instance
        end

        def reset_registry!
          @prometheus_metrics_enabled = nil
          client.reset!
        end

        def counter(name, docstring, base_labels = {})
          when_metrics_enabled do
            client.counter(name, docstring, base_labels)
          end
        end

        def summary(name, docstring, base_labels = {})
          when_metrics_enabled do
            client.summary(name, docstring, base_labels)
          end
        end

        def gauge(name, docstring, base_labels = {}, multiprocess_mode = :all)
          when_metrics_enabled do
            client.gauge(name, docstring, base_labels, multiprocess_mode)
          end
        end

        def histogram(name, docstring, base_labels = {}, buckets = ::Prometheus::Client::Histogram::DEFAULT_BUCKETS)
          when_metrics_enabled do
            client.histogram(name, docstring, base_labels, buckets)
          end
        end

        def error_detected!
          @prometheus_metrics_enabled = nil
          client.disable!
        end

        def prometheus_metrics_enabled?
          prometheus_metrics_enabled_memoized
        end

        private

        def when_metrics_enabled
          if prometheus_metrics_enabled?
            yield
          else
            null_metric
          end
        end

        def prometheus_metrics_enabled_memoized
          @prometheus_metrics_enabled ||=
            (client.enabled? && Gitlab::CurrentSettings.prometheus_metrics_enabled) || false
        end
      end
    end
  end
end
