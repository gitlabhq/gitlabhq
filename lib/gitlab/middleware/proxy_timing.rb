# This Rack middleware is intended to measure the latency between
# gitlab-workhorse forwarding a request to the Rails application and the
# time this middleware is reached.

module Gitlab
  module Middleware
    class ProxyTiming
      def initialize(app)
        @app = app
      end
      
      def call(env)
        proxy_start = env['HTTP_GITLAB_WORHORSE_PROXY_START'].to_f / 1_000_000_000
        if proxy_start > 0
          # send measurement
          puts "\n\n\n#{(Time.now - proxy_start).to_f}\n\n\n"
        end
        @app.call(env)
      end
    end
  end
end
