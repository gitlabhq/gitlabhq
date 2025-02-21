# frozen_string_literal: true

module Gitlab
  module Redis
    class BufferedCounter < ::Gitlab::Redis::MultiStoreWrapper
      class << self
        def config_fallback
          SharedState
        end

        def multistore
          MultiStore.create_using_pool(SharedState.pool, pool, store_name)
        end
      end
    end
  end
end
