# frozen_string_literal: true

module Gitlab
  module Redis
    class DbLoadBalancing < ::Gitlab::Redis::MultiStoreWrapper
      class << self
        # The data we store on DbLoadBalancing used to be stored on SharedState.
        def config_fallback
          SharedState
        end

        def multistore
          MultiStore.create_using_pool(ClusterDbLoadBalancing.pool, pool, store_name)
        end
      end
    end
  end
end
