# frozen_string_literal: true

# This Rack middleware is intended to measure the latency between
# gitlab-workhorse forwarding a request to the Rails application and the
# time this middleware is reached.

module Gitlab
  module Middleware
    class RailsQueueDuration
      GITLAB_RAILS_QUEUE_DURATION_KEY = 'GITLAB_RAILS_QUEUE_DURATION'

      def initialize(app)
        @app = app
      end

      def call(env)
        trans = Gitlab::Metrics.current_transaction
        proxy_start = env['HTTP_GITLAB_WORKHORSE_PROXY_START'].presence
        if trans && proxy_start
          # Time in milliseconds since gitlab-workhorse started the request
          duration = (Time.now.to_f * 1_000) - (proxy_start.to_f / 1_000_000)
          trans.set(:gitlab_transaction_rails_queue_duration_total, duration) do
            multiprocess_mode :livesum
          end

          duration_s = Gitlab::Utils.ms_to_round_sec(duration)
          trans.observe(:gitlab_rails_queue_duration_seconds, duration_s) do
            docstring 'Measures latency between GitLab Workhorse forwarding a request to Rails'
          end
          env[GITLAB_RAILS_QUEUE_DURATION_KEY] = duration_s
        end

        @app.call(env)
      end
    end
  end
end
