# frozen_string_literal: true

require 'opentracing'
require 'grpc'

module Gitlab
  module Tracing
    class GRPCInterceptor < GRPC::ClientInterceptor
      include Common
      include Singleton

      def request_response(request:, call:, method:, metadata:)
        wrap_with_tracing(method, 'unary', metadata) do
          yield
        end
      end

      def client_streamer(requests:, call:, method:, metadata:)
        wrap_with_tracing(method, 'client_stream', metadata) do
          yield
        end
      end

      def server_streamer(request:, call:, method:, metadata:)
        wrap_with_tracing(method, 'server_stream', metadata) do
          yield
        end
      end

      def bidi_streamer(requests:, call:, method:, metadata:)
        wrap_with_tracing(method, 'bidi_stream', metadata) do
          yield
        end
      end

      private

      def wrap_with_tracing(method, grpc_type, metadata)
        tags = {
          'component' =>  'grpc',
          'span.kind' =>  'client',
          'grpc.method' => method,
          'grpc.type' =>   grpc_type
        }

        in_tracing_span(operation_name: "grpc:#{method}", tags: tags) do |span|
          OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)

          yield
        end
      end
    end
  end
end
