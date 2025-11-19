# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    # gRPC client interceptor for recording OpenTelemetry metrics
    # Records call duration, request/response sizes, and status codes
    class MetricsInterceptor < GRPC::ClientInterceptor
      def initialize(cell_id:, topology_service_address:)
        super()
        @metrics = Metrics.new(cell_id: cell_id, topology_service_address: topology_service_address)
      end

      # Intercept unary request-response RPC calls
      def request_response(request:, method:)
        service_name, method_name = extract_service_and_method(method)
        request_size = estimate_message_size(request)

        with_metrics_recording(service: service_name, method: method_name, request_size: request_size) do
          response = yield
          { response: response, response_size: estimate_message_size(response) }
        end
      end

      # Intercept client streaming RPC calls
      def client_streaming(requests:, method:)
        service_name, method_name = extract_service_and_method(method)
        request_size = 0

        with_metrics_recording(service: service_name, method: method_name) do
          # Collect request sizes from the stream
          requests_enum = Enumerator.new do |yielder|
            requests.each do |request|
              request_size += estimate_message_size(request)
              yielder.yield request
            end
          end
          response = yield(requests_enum)
          { response: response, response_size: estimate_message_size(response), request_size: request_size }
        end
      end

      # Intercept server streaming RPC calls
      def server_streaming(request:, method:)
        start_time = monotonic_time
        service_name, method_name = extract_service_and_method(method)
        request_size = estimate_message_size(request)
        response_size = { total: 0 } # Use hash to track size by reference

        begin
          # Call the next handler
          responses_enum = yield

          # Return enumerator that wraps responses and tracks metrics
          Enumerator.new do |yielder|
            responses_enum.each do |response|
              response_size[:total] += estimate_message_size(response)
              yielder.yield response
            end

            # Record metrics after stream completes successfully
            record_metrics(
              service: service_name,
              method: method_name,
              start_time: start_time,
              status_code: GRPC::Core::StatusCodes::OK,
              request_size: request_size,
              response_size: response_size[:total]
            )
          end
        rescue GRPC::BadStatus => e
          record_metrics(
            service: service_name,
            method: method_name,
            start_time: start_time,
            status_code: e.code,
            request_size: request_size,
            response_size: response_size[:total],
            error_type: classify_error(e)
          )
          raise
        rescue StandardError => e
          record_metrics(
            service: service_name,
            method: method_name,
            start_time: start_time,
            status_code: GRPC::Core::StatusCodes::UNKNOWN,
            request_size: request_size,
            response_size: response_size[:total],
            error_type: classify_error(e)
          )
          raise
        end
      end

      # Intercept bidirectional streaming RPC calls
      def bidi_streamer(requests:, method:)
        start_time = monotonic_time
        service_name, method_name = extract_service_and_method(method)
        request_size = { total: 0 } # Use hash to track size by reference
        response_size = { total: 0 } # Use hash to track size by reference

        begin
          # Wrap requests to track sizes
          requests_enum = Enumerator.new do |yielder|
            requests.each do |request|
              request_size[:total] += estimate_message_size(request)
              yielder.yield request
            end
          end

          # Call the next handler
          responses_enum = yield(requests_enum)

          # Return enumerator that wraps responses and tracks metrics
          Enumerator.new do |yielder|
            responses_enum.each do |response|
              response_size[:total] += estimate_message_size(response)
              yielder.yield response
            end

            # Record metrics after stream completes successfully
            record_metrics(
              service: service_name,
              method: method_name,
              start_time: start_time,
              status_code: GRPC::Core::StatusCodes::OK,
              request_size: request_size[:total],
              response_size: response_size[:total]
            )
          end
        rescue GRPC::BadStatus => e
          record_metrics(
            service: service_name,
            method: method_name,
            start_time: start_time,
            status_code: e.code,
            request_size: request_size[:total],
            response_size: response_size[:total],
            error_type: classify_error(e)
          )
          raise
        rescue StandardError => e
          record_metrics(
            service: service_name,
            method: method_name,
            start_time: start_time,
            status_code: GRPC::Core::StatusCodes::UNKNOWN,
            request_size: request_size[:total],
            response_size: response_size[:total],
            error_type: classify_error(e)
          )
          raise
        end
      end

      private

      attr_reader :metrics

      # Extract service name and method name from gRPC method string
      # gRPC method format: "/ServiceName/MethodName"
      def extract_service_and_method(method)
        parts = method.split('/')
        return %w[unknown unknown] if parts.size < 3

        [parts[1].strip, parts[2].strip]
      end

      # Estimate message size using Protobuf serialization
      def estimate_message_size(message)
        return 0 unless message

        # If message responds to :to_proto, use Protobuf serialization
        if message.respond_to?(:to_proto)
          message.to_proto.bytesize
        elsif message.is_a?(String)
          message.bytesize
        elsif message.respond_to?(:encode)
          message.encode('utf-8').bytesize
        else
          0
        end
      rescue StandardError
        # If size estimation fails, return 0 and continue
        0
      end

      # Classify error type from exception
      def classify_error(error)
        # Handle gRPC errors
        if error.is_a?(GRPC::BadStatus)
          code = error.code
          # Map DEADLINE_EXCEEDED to timeout for consistency
          return 'timeout' if code == GRPC::Core::StatusCodes::DEADLINE_EXCEEDED

          return Gitlab::Git::BaseError::GRPC_CODES.fetch(code.to_s, 'unknown_error')
        end

        # Handle non-gRPC errors
        case error
        when Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ENETUNREACH
          'network_error'
        when Timeout::Error
          'timeout'
        else
          'unknown_error'
        end
      end

      # Wrapper method to handle RPC execution with automatic metric recording
      # Handles both success and error cases, recording appropriate metrics
      def with_metrics_recording(service:, method:, request_size: 0)
        start_time = monotonic_time

        begin
          # Execute the RPC call
          result = yield
          response = result[:response]
          response_size = result[:response_size] || 0
          # For streaming requests, request_size may be returned in the result
          final_request_size = result[:request_size] || request_size

          # Record metrics on success
          record_metrics(
            service: service,
            method: method,
            start_time: start_time,
            status_code: GRPC::Core::StatusCodes::OK,
            request_size: final_request_size,
            response_size: response_size
          )

          response
        rescue GRPC::BadStatus => e
          # Record metrics on gRPC error
          record_metrics(
            service: service,
            method: method,
            start_time: start_time,
            status_code: e.code,
            request_size: request_size,
            error_type: classify_error(e)
          )
          raise
        rescue StandardError => e
          # Record metrics on unexpected error
          record_metrics(
            service: service,
            method: method,
            start_time: start_time,
            status_code: GRPC::Core::StatusCodes::UNKNOWN,
            request_size: request_size,
            error_type: classify_error(e)
          )
          raise
        end
      end

      # Record all metrics for the RPC call
      def record_metrics(
        service:, method:, start_time:, status_code:, request_size: 0, response_size: 0,
        error_type: nil)
        duration = monotonic_time - start_time

        # Build labels once and reuse across all metric calls
        labels = metrics.build_labels(service: service, method: method, status_code: status_code)

        # Always record total calls and duration
        metrics.increment_rpc_calls_total(labels: labels)
        metrics.observe_rpc_duration(labels: labels, duration_seconds: duration)

        # Record request/response sizes if available
        metrics.observe_request_size(labels: labels, size_bytes: request_size) if request_size > 0
        metrics.observe_response_size(labels: labels, size_bytes: response_size) if response_size > 0

        # Record failed calls if applicable
        return unless status_code != GRPC::Core::StatusCodes::OK

        metrics.increment_failed_calls_total(labels: labels, error_type: error_type)
      end

      # Get monotonic time for accurate duration measurement
      def monotonic_time
        Gitlab::Metrics::System.monotonic_time
      end
    end
  end
end
