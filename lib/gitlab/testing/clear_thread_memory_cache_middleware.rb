# frozen_string_literal: true

module Gitlab
  module Testing
    class ClearThreadMemoryCacheMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        Gitlab::ThreadMemoryCache.cache_backend.clear

        @app.call(env)
      end
    end
  end
end
