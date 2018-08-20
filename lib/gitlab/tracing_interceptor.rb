require 'securerandom'
require 'opentracing'

class TracingGRPCClientInterceptor < GRPC::ClientInterceptor
  def request_response(request:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    metadata['request_id'] = generate_request_id
    scope = OpenTracing.start_active_span(method)
    begin
      yield
    ensure
      scope.close
    end
  end

  def client_streamer(requests:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    metadata['request_id'] = generate_request_id
    scope = OpenTracing.start_active_span(method)
    begin
      yield
    ensure
      scope.close
    end
  end

  def server_streamer(request:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    metadata['request_id'] = generate_request_id
    scope = OpenTracing.start_active_span(method)
    begin
      yield
    ensure
      scope.close
    end
  end

  def bidi_streamer(requests:, call:, method:, metadata:)
    return yield if OpenTracing.active_span == nil

    metadata['request_id'] = generate_request_id
    scope = OpenTracing.start_active_span(method)
    begin
      yield
    ensure
      scope.close
    end
  end

  private

  def generate_request_id
    SecureRandom.uuid
  end
end
