# frozen_string_literal: true

module Gitlab
  module Middleware
    class QueryAnalyzer
      def initialize(app)
        @app = app
      end

      def call(env)
        ::Gitlab::Database::QueryAnalyzer.instance.within { @app.call(env) }
      end
    end
  end
end
