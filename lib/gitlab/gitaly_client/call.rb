# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class Call
      def initialize(storage, service, rpc, request, remote_storage, timeout, gitaly_context: {})
        @storage = storage
        @service = service
        @rpc = rpc
        @request = request
        @remote_storage = remote_storage
        @timeout = timeout
        @duration = 0
        @gitaly_context = gitaly_context
      end

      def call(&block)
        # Circuit breaker integration:
        # We check if the circuit is open before making any Gitaly request to fail fast.
        #
        # We cannot wrap the entire call in circuit_breaker.call because:
        # 1. For streaming responses, failures occur lazily during enumeration, not during execute
        # 2. Wrapping both here and in instrument_stream would cause double-counting of failures
        # Instead, we: check! first, then record success/failure after the response type is known
        circuit_breaker.check!

        # When the response is an enumerator (streamed responses), the success
        # or failure is only known once the stream is consumed, so the SLI is
        # recorded lazily in `instrument_stream` instead of the `ensure` below.
        streaming = false
        error = nil
        operation = nil
        response = recording_request do
          operation = GitalyClient.execute(@storage, @service, @rpc, @request,
            remote_storage: @remote_storage,
            timeout: @timeout,
            gitaly_context: @gitaly_context, &block)
          operation.execute
        end

        if response.is_a?(Enumerator)
          # When the given response is an enumerator (coming from streamed
          # responses), we wrap it in order to properly measure the stream
          # consumption as it happens.
          #
          # store_timings and trailer-reading are not called in that scenario
          # as they need to be handled lazily in the custom Enumerator context.
          streaming = true
          instrument_stream(response, operation)
        else
          accumulate_cost(operation)
          store_timings
          # Non-streaming successful responses:
          # circuit_breaker.call { response } wraps the final response return to track successful completions in the circuit breaker's metrics,
          # because we need to consider successful responses to calculate success rate
          circuit_breaker.call { response }
        end
      rescue Gitlab::Git::ResourceExhaustedError => err
        error = err
        raise
      rescue StandardError => err
        error = err
        accumulate_cost(operation)
        store_timings
        set_gitaly_error_metadata(err) if err.is_a?(::GRPC::BadStatus)

        # Exception path:
        # When any error occurs, it's re-raised through the circuit breaker
        # so GRPC::ResourceExhausted errors increment the failure counter.
        circuit_breaker.call { raise err }
      ensure
        # Record the SLI once per non-streaming call, passing the exception (if
        # any) so the SLI decides what counts as an error. Streaming calls are
        # recorded in `instrument_stream` once the stream is consumed.
        record_client_call_sli(error: error) unless streaming
      end

      private

      def circuit_breaker
        @circuit_breaker ||= CircuitBreaker.new(service: @service, rpc: @rpc, storage: @storage)
      end

      def instrument_stream(response, operation)
        error = nil

        Enumerator.new do |yielder|
          loop do
            # Streaming enumerator path:
            # For streaming responses, each next call is wrapped because failures can occur during iteration, not just during the initial call.
            # This ensures the circuit opens even when errors happen while consuming the stream.
            value = recording_request { circuit_breaker.call { response.next } }

            yielder.yield(value)
          end
        rescue ::GRPC::BadStatus => err
          error = err
          set_gitaly_error_metadata(err)
          raise err
        rescue StandardError => err
          # Capture other errors (e.g. the circuit-breaker fast-fail) for the
          # SLI only. The application behaviour is unchanged: the error is
          # re-raised as before, just like an uncaught error would be.
          error = err
          raise err
        ensure
          accumulate_cost(operation)
          store_timings
          record_client_call_sli(error: error)
        end
      end

      def accumulate_cost(operation)
        return unless Feature.enabled?(:request_cost_headers, :current_request, type: :gitlab_com_derisk)
        return unless operation

        cost = operation.trailing_metadata&.dig('x-gitaly-cost').to_i
        Gitlab::RequestCost.current.add(cost, resource: :gitaly) if cost > 0
      rescue StandardError => e
        Gitlab::AppLogger.warn(
          message: "Failed to accumulate Gitaly cost",
          error_class: e.class.name,
          error_message: e.message
        )
      end

      def recording_request
        @start = Gitlab::Metrics::System.monotonic_time

        yield
      ensure
        @duration += Gitlab::Metrics::System.monotonic_time - @start
      end

      def store_timings
        GitalyClient.add_query_time(@duration)

        return unless Gitlab::PerformanceBar.enabled_for_request?

        request_hash = @request.is_a?(Google::Protobuf::MessageExts) ? @request.to_h : {}

        GitalyClient.add_call_details(
          start: @start,
          feature: "#{@service}##{@rpc}",
          duration: @duration,
          request: request_hash,
          rpc: @rpc,
          backtrace: Gitlab::BacktraceCleaner.clean_backtrace(caller)
        )
      end

      def set_gitaly_error_metadata(err)
        err.metadata[::Gitlab::Git::BaseError::METADATA_KEY] = {
          storage: @storage,
          address: ::Gitlab::GitalyClient.address(@storage),
          service: @service,
          rpc: @rpc
        }
      end

      def record_client_call_sli(error: nil)
        Gitlab::Metrics::GitalyClientSlis.record_error_rate(
          storage: @storage,
          error: error
        )
      end
    end
  end
end
