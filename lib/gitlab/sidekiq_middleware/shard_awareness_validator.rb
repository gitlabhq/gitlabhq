# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class ShardAwarenessValidator
      def call(_worker, _job, _queue)
        # Scopes shard-awareness validation to Gitlab-logic since Sidekiq
        # internally uses Sidekiq.redis for job fetching, cron polling, heartbeats, etc
        ::Gitlab::SidekiqSharding::Validator.enabled do
          yield
        end
      end
    end
  end
end
