# frozen_string_literal: true

module Gitlab
  module Middleware
    class SidekiqShardAwarenessValidation
      def initialize(app)
        @app = app
      end

      def call(env)
        ::Gitlab::SidekiqSharding::Validator.enabled do
          @app.call(env)
        end
      end
    end
  end
end
