# frozen_string_literal: true

module Gitlab
  module TopologyServiceClient
    class InstrumentationInterceptor < GRPC::ClientInterceptor
      extend ::Gitlab::Utils::Override

      # Only unary calls are timed, because every Topology Service RPC is unary today.
      # A new streaming RPC needs its own override here, or its calls are not logged.
      override :request_response
      def request_response(request: nil, call: nil, method: nil, metadata: nil) # rubocop:disable Lint/UnusedMethodArgument -- call, method and metadata are required by the gRPC interceptor interface
        start_time = ::Gitlab::Metrics::System.monotonic_time

        yield
      ensure
        ::Gitlab::Instrumentation::TopologyService.add_call(
          request: request,
          duration: ::Gitlab::Metrics::System.monotonic_time - start_time
        )
      end
    end
  end
end
