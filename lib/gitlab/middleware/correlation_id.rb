# frozen_string_literal: true

# A dumb middleware that steals correlation id
# and sets it as a global context for the request
module Gitlab
  module Middleware
    class CorrelationId
      include ActionView::Helpers::TagHelper

      def initialize(app)
        @app = app
      end

      def call(env)
        ::Labkit::Correlation::CorrelationId.use_id(correlation_id(env)) do
          @app.call(env)
        end
      end

      private

      def correlation_id(env)
        request(env).request_id
      end

      def request(env)
        ActionDispatch::Request.new(env)
      end
    end
  end
end
