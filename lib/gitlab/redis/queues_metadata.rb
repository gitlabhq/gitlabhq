# frozen_string_literal: true

module Gitlab
  module Redis
    class QueuesMetadata < ::Gitlab::Redis::Wrapper
      class << self
        def config_fallback
          Queues
        end

        private

        def redis
          primary_store = ::Redis.new(params)
          secondary_store = ::Redis.new(config_fallback.params)

          MultiStore.new(primary_store, secondary_store, name.demodulize)
        end
      end
    end
  end
end
