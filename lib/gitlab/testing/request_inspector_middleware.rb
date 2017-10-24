# rubocop:disable Style/ClassVars

module Gitlab
  module Testing
    class RequestInspectorMiddleware
      @@log_requests = Concurrent::AtomicBoolean.new(false)
      @@logged_requests = Concurrent::Array.new

      # Resets the current request log and starts logging requests
      def self.log_requests!
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
        request_headers = env_http_headers(env)
        status, headers, body = @app.call(env)

        request = OpenStruct.new(
          url: url,
          status_code: status,
          request_headers: request_headers,
          response_headers: headers
        )
        log_request request

        [status, headers, body]
      end

      private

      def env_http_headers(env)
        Hash[*env.select {|k, v| k.start_with? 'HTTP_'}
          .collect {|k, v| [k.sub(/^HTTP_/, ''), v]}
          .collect {|k, v| [k.split('_').collect(&:capitalize).join('-'), v]}
          .sort
          .flatten]
      end

      def log_request(response)
        @@logged_requests.push(response)
      end
    end
  end
end
