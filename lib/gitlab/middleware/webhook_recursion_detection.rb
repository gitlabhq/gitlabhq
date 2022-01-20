# frozen_string_literal: true

module Gitlab
  module Middleware
    class WebhookRecursionDetection
      def initialize(app)
        @app = app
      end

      def call(env)
        headers = ActionDispatch::Request.new(env).headers

        ::Gitlab::WebHooks::RecursionDetection.set_from_headers(headers)

        @app.call(env)
      end
    end
  end
end
