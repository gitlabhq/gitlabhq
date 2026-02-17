# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    # gRPC client interceptor for enforcing concurrency limits on Topology Service requests
    # Implements circuit breaker logic to prevent database connection exhaustion
    #
    # This interceptor enforces a global concurrency limit: at any moment in time,
    # there should not be more than the configured limit of concurrent requests
    # to the Topology Service. This applies to ALL requests across the entire cell,
    # not per-request or per-user.
    #
    # Stale request cleanup is handled by StaleRequestsCleanupCronWorker which runs
    # every 5 minutes to remove entries older than TRACKING_KEY_TTL.
    #
    # The circuit breaker is implemented as a result of the ADR: https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/decisions/021_claims_in_database_transaction/#decision

    class ConcurrencyLimitInterceptor < GRPC::ClientInterceptor
      # Only track concurrency for these RPCs that hold database transactions
      TRACKED_RPCS = %w[BeginUpdate CommitUpdate RollbackUpdate].freeze

      # Class-level cache to avoid repeated O(n) string split operations across requests
      TRACKED_METHOD_CACHE = Concurrent::Map.new

      # rubocop:disable Lint/UnusedMethodArgument -- gRPC interceptor interface requires these parameters
      def request_response(request: nil, call: nil, method: nil, metadata: nil)
        intercept(method) { yield }
      end

      def client_streaming(requests: nil, call: nil, method: nil, metadata: nil)
        intercept(method) { yield }
      end

      def server_streaming(request: nil, call: nil, method: nil, metadata: nil)
        intercept(method, streaming: true) { yield }
      end

      def bidi_streamer(requests: nil, call: nil, method: nil, metadata: nil)
        intercept(method, streaming: true) { yield }
      end

      private

      def intercept(method, streaming: false)
        return yield unless tracked_rpc?(method)

        with_concurrency_limit(method, streaming: streaming) { yield }
      end
      # rubocop:enable Lint/UnusedMethodArgument

      def tracked_rpc?(method)
        return false if method.blank?

        TRACKED_METHOD_CACHE.compute_if_absent(method) do
          TRACKED_RPCS.include?(ConcurrencyLimitService.extract_method_name(method))
        end
      end

      # @param method [String] the gRPC method being called
      # @param streaming [Boolean] whether this is a streaming RPC that returns an Enumerator
      def with_concurrency_limit(method, streaming: false)
        request_id = ConcurrencyLimitService.track_request_start(grpc_method: method)

        begin
          # request_id is nil when limit was exceeded (Lua script rejected it)
          handle_rejected_request!(method) if request_id.nil?

          result = yield
          streaming ? wrap_streaming_response!(result, request_id) : result
        ensure
          # Only cleanup non-streaming requests here
          # Streaming requests are cleaned up when the enumerator completes
          ConcurrencyLimitService.track_request_end(request_id) unless streaming
        end
      end

      def wrap_streaming_response!(enum, request_id)
        if enum.nil?
          ConcurrencyLimitService.track_request_end(request_id)
          return enum
        end

        Enumerator.new do |yielder|
          enum.each { |item| yielder.yield item }
        rescue StandardError => e
          Gitlab::ErrorTracking.track_exception(e, request_id: request_id)
          raise
        ensure
          ConcurrencyLimitService.track_request_end(request_id)
        end
      end

      def handle_rejected_request!(method)
        mode = ConcurrencyLimitService.enforce_mode_enabled? ? 'enforce' : 'log_only'
        log_rejection(method, mode: mode)

        return unless mode == 'enforce'

        raise GRPC::ResourceExhausted, "Topology Service concurrency limit exceeded for #{method}"
      end

      def log_rejection(method, mode:)
        message = if mode == 'enforce'
                    'Topology Service request rejected due to concurrency limit'
                  else
                    'Topology Service concurrency limit would be exceeded'
                  end

        Gitlab::AppLogger.warn(
          message: message,
          grpc_method: method,
          configured_limit: ConcurrencyLimitService.concurrency_limit,
          mode: mode
        )
      end
    end
  end
end
