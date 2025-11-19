# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    # Instrumentation for topology service gRPC metrics
    # Implements standard OpenTelemetry gRPC metrics as Prometheus equivalents
    class Metrics
      extend Gitlab::Utils::StrongMemoize

      # Histogram buckets for duration measurements (seconds)
      # Focuses on latency SLOs
      DURATION_BUCKETS = [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5].freeze

      # Histogram buckets for size measurements (bytes)
      # Uses exponential buckets for variable sizes
      SIZE_BUCKETS = [100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000].freeze

      def self.metric(name, desc, type:, buckets: nil, extra_labels: {})
        labels = {
          rpc_service: nil,
          rpc_method: nil,
          rpc_status: nil,
          rpc_system: 'grpc',
          cell_id: nil,
          topology_service_address: nil
        }.merge(extra_labels)

        case type
        when :histogram
          ::Gitlab::Metrics.histogram(name, desc, labels, buckets)
        when :counter
          ::Gitlab::Metrics.counter(name, desc, labels)
        else
          raise ArgumentError, "Unsupported metric type: #{type}"
        end
      end

      def self.rpc_duration_histogram
        strong_memoize(:rpc_duration_histogram) do
          metric(:topology_service_rpc_duration_seconds,
            'RPC call duration in seconds',
            type: :histogram,
            buckets: DURATION_BUCKETS)
        end
      end

      def self.request_size_histogram
        strong_memoize(:request_size_histogram) do
          metric(:topology_service_rpc_request_size_bytes,
            'RPC request size in bytes',
            type: :histogram,
            buckets: SIZE_BUCKETS)
        end
      end

      def self.response_size_histogram
        strong_memoize(:response_size_histogram) do
          metric(:topology_service_rpc_response_size_bytes,
            'RPC response size in bytes',
            type: :histogram,
            buckets: SIZE_BUCKETS)
        end
      end

      def self.rpc_calls_total_counter
        strong_memoize(:rpc_calls_total_counter) do
          metric(:topology_service_rpc_calls_total,
            'Total number of RPC calls',
            type: :counter)
        end
      end

      def self.failed_calls_total_counter
        strong_memoize(:failed_calls_total_counter) do
          metric(:topology_service_rpc_failed_calls_total,
            'Total number of failed RPC calls',
            type: :counter)
        end
      end

      def initialize(cell_id:, topology_service_address:)
        @cell_id = cell_id
        @topology_service_address = topology_service_address
      end

      # Record RPC call duration
      def observe_rpc_duration(labels:, duration_seconds:)
        self.class.rpc_duration_histogram.observe(labels, duration_seconds)
      rescue StandardError => e
        # Gracefully handle metric recording failures without blocking gRPC calls
        log_metric_error('Failed to observe RPC duration', e)
      end

      # Record RPC request size
      def observe_request_size(labels:, size_bytes:)
        self.class.request_size_histogram.observe(labels, size_bytes)
      rescue StandardError => e
        log_metric_error('Failed to observe request size', e)
      end

      # Record RPC response size
      def observe_response_size(labels:, size_bytes:)
        self.class.response_size_histogram.observe(labels, size_bytes)
      rescue StandardError => e
        log_metric_error('Failed to observe response size', e)
      end

      # Increment total RPC calls counter
      def increment_rpc_calls_total(labels:)
        self.class.rpc_calls_total_counter.increment(labels)
      rescue StandardError => e
        log_metric_error('Failed to increment RPC calls total', e)
      end

      # Increment failed RPC calls counter
      def increment_failed_calls_total(labels:, error_type: nil)
        labels_with_error = labels.dup
        labels_with_error[:error_type] = error_type if error_type
        self.class.failed_calls_total_counter.increment(labels_with_error)
      rescue StandardError => e
        log_metric_error('Failed to increment failed calls total', e)
      end

      # Build labels hash for metrics
      # This method is public to allow interceptor to build labels once and reuse them
      def build_labels(service:, method:, status_code:)
        {
          rpc_service: service,
          rpc_method: method,
          rpc_status: status_code_to_label(status_code),
          rpc_system: 'grpc',
          cell_id: cell_id,
          topology_service_address: topology_service_address
        }
      end

      # Metric definitions using strong_memoize for thread-safe caching

      private

      attr_reader :cell_id, :topology_service_address

      def status_code_to_label(status_code)
        Gitlab::Git::BaseError::GRPC_CODES.fetch(status_code.to_s, 'unknown').upcase
      end

      def log_metric_error(message, error)
        # Log metric failures at debug level only, never block gRPC calls
        Gitlab::AppLogger.debug("#{message}: #{error.message}")
      end
    end
  end
end
