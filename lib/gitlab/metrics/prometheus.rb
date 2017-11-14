require 'prometheus/client'

module Gitlab
  module Metrics
    module Prometheus
      include Gitlab::CurrentSettings

      REGISTRY_MUTEX = Mutex.new
      PROVIDER_MUTEX = Mutex.new

      def metrics_folder_present?
        multiprocess_files_dir = ::Prometheus::Client.configuration.multiprocess_files_dir

        multiprocess_files_dir &&
          ::Dir.exist?(multiprocess_files_dir) &&
          ::File.writable?(multiprocess_files_dir)
      end

      def prometheus_metrics_enabled?
        return @prometheus_metrics_enabled if defined?(@prometheus_metrics_enabled)

        @prometheus_metrics_enabled = prometheus_metrics_enabled_unmemoized
      end

      def registry
        return @registry if @registry

        REGISTRY_MUTEX.synchronize do
          @registry ||= ::Prometheus::Client.registry
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

      def histogram(name, docstring, base_labels = {}, buckets = ::Prometheus::Client::Histogram::DEFAULT_BUCKETS)
        safe_provide_metric(:histogram, name, docstring, base_labels, buckets)
      end

      private

      def safe_provide_metric(method, name, *args)
        metric = provide_metric(name)
        return metric if metric

        PROVIDER_MUTEX.synchronize do
          provide_metric(name) || registry.method(method).call(name, *args)
        end
      end

      def provide_metric(name)
        if prometheus_metrics_enabled?
          registry.get(name)
        else
          NullMetric.new
        end
      end

      def prometheus_metrics_enabled_unmemoized
        metrics_folder_present? && current_application_settings[:prometheus_metrics_enabled] || false
      end
    end
  end
end
