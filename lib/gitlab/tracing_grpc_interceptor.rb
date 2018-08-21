require 'securerandom'
require 'opentracing'

class TracingGRPCClientInterceptor < GRPC::ClientInterceptor
  def initialize(tracer: OpenTracing.global_tracer)
    @tracer = tracer
  end

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
    return yield if OpenTracing.active_span == nil

    span = OpenTracing.start_span(method,
      tags: {
        'component' => 'gRPC',
        'span.kind' => 'client',
        'grpc.method' => method,
        'grpc.type' => grpc_type,
      }
    )

    OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)

    begin
      yield
    rescue StandardError => e
      span.set_tag('error', true)
      span.log_kv(
        event: 'error',
        :'error.kind' => e.class.to_s,
        :'error.object' => e,
        message: e.message,
        stack: e.backtrace.join("\n")
      )
      raise e
    ensure
      span.finish
    end
  end
end
