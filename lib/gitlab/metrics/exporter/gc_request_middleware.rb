# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class GcRequestMiddleware
        def initialize(app)
          @app = app
        end

        def call(env)
          @app.call(env).tap do
            GC.start
          end
        end
      end
    end
  end
end
