# This solves a bug with a X-Senfile header that wouldn't be set properly, see
# https://github.com/peek/peek-performance_bar/pull/27
module Gitlab
  module PerformanceBar
    module PeekPerformanceBarWithRackBody
      def call(env)
        @env = env
        reset_stats

        @total_requests += 1
        first_request if @total_requests == 1

        env['process.request_start'] = @start.to_f
        env['process.total_requests'] = total_requests

        status, headers, body = @app.call(env)
        body = Rack::BodyProxy.new(body) { record_request }
        [status, headers, body]
      end
    end
  end
end
