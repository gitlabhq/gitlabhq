# This Rack middleware is intended to measure the latency between
# gitlab-workhorse forwarding a request to the Rails application and the
# time this middleware is reached.

module Gitlab
  module Middleware
    class RailsQueueDuration
      def initialize(app)
        @app = app
      end
      
      def call(env)
        trans = Gitlab::Metrics.current_transaction
        proxy_start = env['HTTP_GITLAB_WORKHORSE_PROXY_START'].presence
        if trans && proxy_start
          # Time in milliseconds since gitlab-workhorse started the request
          trans.set(:rails_queue_duration, Time.now.to_f * 1_000 - proxy_start.to_f / 1_000_000)
        end

        @app.call(env)
      end
    end
  end
end
