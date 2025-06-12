# frozen_string_literal: true

module Gitlab
  module Metrics
    module Prometheus
      extend ActiveSupport::Concern

      REGISTRY_MUTEX = Mutex.new
      PROVIDER_MUTEX = Mutex.new

      class_methods do
        include Gitlab::Utils::StrongMemoize

        @error = false

        def error?
          @error
        end

        def client
          ::Prometheus::Client
        end

        def null_metric
          NullMetric.instance
        end

        def metrics_folder_present?
          multiprocess_files_dir = client.configuration.multiprocess_files_dir

          multiprocess_files_dir &&
            ::Dir.exist?(multiprocess_files_dir) &&
            ::File.writable?(multiprocess_files_dir)
        end

        def prometheus_metrics_enabled?
          strong_memoize(:prometheus_metrics_enabled) do
            prometheus_metrics_enabled_unmemoized
          end
        end

        def reset_registry!
          clear_memoization(:registry)
          clear_memoization(:prometheus_metrics_enabled)

          REGISTRY_MUTEX.synchronize do
            client.cleanup!
            client.reset!
          end
        end

        def registry
          strong_memoize(:registry) do
            REGISTRY_MUTEX.synchronize do
              strong_memoize(:registry) do
                client.registry
              end
            end
          end
        end

        def counter(name, docstring, base_labels = {})
          safe_provide_metric(:counter, name, docstring, base_labels)
        end

        def summary(name, docstring, base_labels = {})
          safe_provide_metric(:summary, name, docstring, base_labels)
        end

        def gauge(name, docstring, base_labels = {}, multiprocess_mode = :all)
          safe_provide_metric(:gauge, name, docstring, base_labels, multiprocess_mode)
        end

        def histogram(name, docstring, base_labels = {}, buckets = client::Histogram::DEFAULT_BUCKETS)
          safe_provide_metric(:histogram, name, docstring, base_labels, buckets)
        end

        def error_detected!
          set_error!(true)
        end

        def clear_errors!
          set_error!(false)
        end

        def set_error!(status)
          clear_memoization(:prometheus_metrics_enabled)

          PROVIDER_MUTEX.synchronize do
            @error = status
          end
        end

        private

        def safe_provide_metric(metric_type, metric_name, *args)
          PROVIDER_MUTEX.synchronize do
            provide_metric(metric_type, metric_name, *args)
          end
        end

        def provide_metric(metric_type, metric_name, *args)
          if prometheus_metrics_enabled?
            registry.get(metric_name) || registry.method(metric_type).call(metric_name, *args)
          else
            null_metric
          end
        end

        def prometheus_metrics_enabled_unmemoized
          (!error? && metrics_folder_present? && Gitlab::CurrentSettings.prometheus_metrics_enabled) || false
        end
      end
    end
  end
end
