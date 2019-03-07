# frozen_string_literal: true

require 'opentracing'

module Gitlab
  module Tracing
    class RackMiddleware
      include Common

      REQUEST_METHOD = 'REQUEST_METHOD'

      def initialize(app)
        @app = app
      end

      def call(env)
        method = env[REQUEST_METHOD]

        context = tracer.extract(OpenTracing::FORMAT_RACK, env)
        tags = {
          'component' =>   'rack',
          'span.kind' =>   'server',
          'http.method' => method,
          'http.url' =>    self.class.build_sanitized_url_from_env(env)
        }

        in_tracing_span(operation_name: "http:#{method}", child_of: context, tags: tags) do |span|
          @app.call(env).tap do |status_code, _headers, _body|
            span.set_tag('http.status_code', status_code)
          end
        end
      end

      # Generate a sanitized (safe) request URL from the rack environment
      def self.build_sanitized_url_from_env(env)
        request = ActionDispatch::Request.new(env)

        original_url = request.original_url
        uri = URI.parse(original_url)
        uri.query = request.filtered_parameters.to_query if uri.query.present?

        uri.to_s
      end
    end
  end
end
