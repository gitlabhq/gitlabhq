# frozen_string_literal: true

module Gitlab
  module Middleware
    # Exposes per-request Gitaly cost and namespace as response headers for
    # Cloudflare complexity-based rate limiting.
    class RequestCost
      HEADER_SCORE_GITALY = 'x-gitlab-score-gitaly'
      HEADER_NAMESPACE    = 'x-gitlab-namespace'

      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        add_cost_headers(headers)
        [status, headers, body]
      end

      private

      def add_cost_headers(headers)
        return unless ::Feature.enabled?(:request_cost_headers, :current_request, type: :gitlab_com_derisk)

        gitaly_cost = ::Gitlab::RequestCost.current.get(:gitaly)
        return unless gitaly_cost > 0

        namespace_path = ::Gitlab::ApplicationContext.current_context_attribute(:root_namespace)
        return unless namespace_path

        headers[HEADER_SCORE_GITALY] = gitaly_cost.to_s
        headers[HEADER_NAMESPACE] = namespace_path
      end
    end
  end
end
