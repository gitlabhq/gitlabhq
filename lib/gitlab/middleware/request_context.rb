# frozen_string_literal: true

module Gitlab
  module Middleware
    class RequestContext
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        Gitlab::RequestContext.start_request_context(request: request)
        Gitlab::RequestContext.start_thread_context

        @app.call(env)
      end
    end
  end
end
