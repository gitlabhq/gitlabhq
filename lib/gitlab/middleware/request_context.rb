# frozen_string_literal: true

module Gitlab
  module Middleware
    class RequestContext
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        ensure_gvl_instrumentation
        Gitlab::RequestContext.start_request_context(request: request)
        Gitlab::RequestContext.start_thread_context

        # On ApplicationContext rather than RequestContext so jobs enqueued by
        # this request inherit it through Labkit.
        client = Gitlab::Tracking::ClientIdentity.from_request(request)

        Gitlab::ApplicationContext.with_context({ client_type: client.type, client_name: client.name }.compact) do
          @app.call(env)
        end
      end

      private

      def ensure_gvl_instrumentation
        ::Gitlab::Instrumentation::Gvl.toggle(
          Feature.enabled?(:enable_puma_gvl_metrics, :current_pod, type: :ops)
        )
      end
    end
  end
end
