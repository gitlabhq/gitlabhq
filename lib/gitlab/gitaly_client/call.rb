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
        response = recording_request do
          GitalyClient.execute(@storage, @service, @rpc, @request, remote_storage: @remote_storage, timeout: @timeout, gitaly_context: @gitaly_context, &block)
        end

        if response.is_a?(Enumerator)
          # When the given response is an enumerator (coming from streamed
          # responses), we wrap it in order to properly measure the stream
          # consumption as it happens.
          #
          # store_timings is not called in that scenario as needs to be
          # handled lazily in the custom Enumerator context.
          instrument_stream(response)
        else
          store_timings
          response
        end
      rescue StandardError => err
        store_timings
        set_gitaly_error_metadata(err) if err.is_a?(::GRPC::BadStatus)

        raise err
      end

      private

      def instrument_stream(response)
        Enumerator.new do |yielder|
          loop do
            value = recording_request { response.next }

            yielder.yield(value)
          end
        rescue ::GRPC::BadStatus => err
          set_gitaly_error_metadata(err)
          raise err
        ensure
          store_timings
        end
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
    end
  end
end
