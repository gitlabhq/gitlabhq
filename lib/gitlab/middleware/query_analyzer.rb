# frozen_string_literal: true

module Gitlab
  module Middleware
    class QueryAnalyzer
      REQUEST_METHOD_KEY = :query_analyzer_http_request_method

      def self.http_request_method
        ::Gitlab::SafeRequestStore[REQUEST_METHOD_KEY]
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        ::Gitlab::SafeRequestStore[REQUEST_METHOD_KEY] = env['REQUEST_METHOD']

        ::Gitlab::Database::QueryAnalyzer.instance.within { @app.call(env) }
      end
    end
  end
end
