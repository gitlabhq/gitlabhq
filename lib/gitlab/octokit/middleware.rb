# frozen_string_literal: true

module Gitlab
  module Octokit
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        Gitlab::UrlBlocker.validate!(env[:url], { allow_localhost: allow_local_requests?, allow_local_network: allow_local_requests? })

        @app.call(env)
      end

      private

      def allow_local_requests?
        Gitlab::CurrentSettings.allow_local_requests_from_hooks_and_services?
      end
    end
  end
end
