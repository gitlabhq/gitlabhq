# frozen_string_literal: true

module Gitlab
  module Testing
    class ClearProcessMemoryCacheMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        Gitlab::ProcessMemoryCache.cache_backend.clear

        @app.call(env)
      end
    end
  end
end
