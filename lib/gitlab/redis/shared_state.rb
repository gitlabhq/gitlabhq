# frozen_string_literal: true

module Gitlab
  module Redis
    class SharedState < ::Gitlab::Redis::Wrapper
      def self.redis
        primary_store = ::Redis.new(ClusterSharedState.params)
        secondary_store = ::Redis.new(params)

        MultiStore.new(primary_store, secondary_store, store_name)
      end
    end
  end
end
