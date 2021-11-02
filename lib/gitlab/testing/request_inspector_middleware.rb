# frozen_string_literal: true

# rubocop:disable Style/ClassVars

module Gitlab
  module Testing
    class RequestInspectorMiddleware
      @@log_requests = Concurrent::AtomicBoolean.new(false)
      @@logged_requests = Concurrent::Array.new
      @@inject_headers = Concurrent::Hash.new

      Request = Struct.new(:url, :status_code, :request_headers, :response_headers, :body, keyword_init: true)

      # Resets the current request log and starts logging requests
      def self.log_requests!(headers = {})
        @@inject_headers.replace(headers)
        @@logged_requests.replace([])
        @@log_requests.value = true
      end

      # Stops logging requests
      def self.stop_logging!
        @@log_requests.value = false
      end

      def self.requests
        @@logged_requests
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless @@log_requests.true?

        url = env['REQUEST_URI']
        env.merge! http_headers_env(@@inject_headers) if @@inject_headers.any?
        request_headers = env_http_headers(env)
        status, headers, body = @app.call(env)

        full_body = +''
        body.each { |b| full_body << b }

        request = Request.new(
          url: url,
          status_code: status,
          request_headers: request_headers,
          response_headers: headers,
          body: full_body
        )
        log_request request

        [status, headers, body]
      end

      private

      def env_http_headers(env)
        Hash[*env.select { |k, v| k.start_with? 'HTTP_' }
          .collect { |k, v| [k.sub(/^HTTP_/, ''), v] }
          .collect { |k, v| [k.split('_').collect(&:capitalize).join('-'), v] }
          .sort
          .flatten]
      end

      def http_headers_env(headers)
        Hash[*headers
          .collect { |k, v| [k.split('-').collect(&:upcase).join('_'), v] }
          .collect { |k, v| [k.prepend('HTTP_'), v] }
          .flatten]
      end

      def log_request(response)
        @@logged_requests.push(response)
      end
    end
  end
end
