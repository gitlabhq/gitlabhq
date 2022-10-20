# frozen_string_literal: true

module Gitlab
  module Redis
    # Pseudo-store to transition `Gitlab::SidekiqStatus` from
    # using `Sidekiq.redis` to using the `SharedState` redis store.
    class SidekiqStatus < ::Gitlab::Redis::Wrapper
      class << self
        def store_name
          'SharedState'
        end

        private

        def redis
          primary_store = ::Redis.new(Gitlab::Redis::SharedState.params)
          secondary_store = ::Redis.new(Gitlab::Redis::Queues.params) # rubocop:disable Cop/RedisQueueUsage

          MultiStore.new(primary_store, secondary_store, name.demodulize)
        end
      end
    end
  end
end
