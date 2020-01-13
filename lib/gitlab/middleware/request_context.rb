# frozen_string_literal: true

module Gitlab
  module Middleware
    class RequestContext
      def initialize(app)
        @app = app
      end

      def call(env)
        # We should be using ActionDispatch::Request instead of
        # Rack::Request to be consistent with Rails, but due to a Rails
        # bug described in
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/58573#note_149799010
        # hosts behind a load balancer will only see 127.0.0.1 for the
        # load balancer's IP.
        req = Rack::Request.new(env)

        Gitlab::RequestContext.instance.client_ip = req.ip
        Gitlab::RequestContext.instance.start_thread_cpu_time = Gitlab::Metrics::System.thread_cpu_time
        Gitlab::RequestContext.instance.request_start_time = Gitlab::Metrics::System.real_time

        @app.call(env)
      end
    end
  end
end
