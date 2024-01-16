# frozen_string_literal: true

module Gitlab
  module Redis
    class SharedState < ::Gitlab::Redis::MultiStoreWrapper
      def self.multistore
        MultiStore.new(ClusterSharedState.pool, pool, store_name)
      end
    end
  end
end
