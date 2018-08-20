require 'securerandom'
require 'opentracing'

class TracingGRPCClientInterceptor < GRPC::ClientInterceptor
  def request_response(request:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    span = OpenTracing.start_span(method)
    if span
      span.set_tag('grpc.type','unary')
      span.set_tag('component','gRPC')
      span.set_tag('span.kind','client')
    end

    OpenTracing.scope_manager.activate(span)

    begin
      OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)
      yield
    ensure
      span.finish
    end
  end

  def client_streamer(requests:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    span = OpenTracing.start_span(method)
    if span
      span.set_tag('grpc.type','client_stream')
      span.set_tag('component','gRPC')
      span.set_tag('span.kind','client')
    end

    OpenTracing.scope_manager.activate(span)

    begin
      OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)
      yield
    ensure
      span.finish
    end
  end

  def server_streamer(request:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    span = OpenTracing.start_span(method)
    if span
      span.set_tag('grpc.type','server_stream')
      span.set_tag('component','gRPC')
      span.set_tag('span.kind','client')
    end


    OpenTracing.scope_manager.activate(span)

    begin
      OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)
      yield
    ensure
      span.finish
    end
  end

  def bidi_streamer(requests:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    span = OpenTracing.start_span(method)
    if span
      span.set_tag('grpc.type','bidi_stream')
      span.set_tag('component','gRPC')
      span.set_tag('span.kind','client')
    end

    OpenTracing.scope_manager.activate(span)

    begin
      OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, metadata)
      yield
    ensure
      span.finish
    end
  end

end
