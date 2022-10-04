# frozen_string_literal: true

module Gitlab
  module Redis
    # Pseudo-store to transition `Gitlab::SidekiqMiddleware::DuplicateJobs` from
    # using `Sidekiq.redis` to using the `SharedState` redis store.
    class DuplicateJobs < ::Gitlab::Redis::Wrapper
      class << self
        def store_name
          'SharedState'
        end

        private

        def redis
          primary_store = ::Redis.new(Gitlab::Redis::SharedState.params)

          # `Sidekiq.redis` is a namespaced redis connection. This means keys are actually being stored under
          # "resque:gitlab:resque:gitlab:duplicate:". For backwards compatibility, we make the secondary store
          # namespaced in the same way, but omit it from the primary so keys have proper format there.
          # rubocop:disable Cop/RedisQueueUsage
          secondary_store = ::Redis::Namespace.new(
            Gitlab::Redis::Queues::SIDEKIQ_NAMESPACE, redis: ::Redis.new(Gitlab::Redis::Queues.params)
          )
          # rubocop:enable Cop/RedisQueueUsage

          MultiStore.new(primary_store, secondary_store, name.demodulize)
        end
      end
    end
  end
end
