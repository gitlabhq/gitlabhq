# frozen_string_literal: true

module Gitlab
  module Redis
    class TraceChunks < ::Gitlab::Redis::MultiStoreWrapper
      class << self
        # The data we store on TraceChunks used to be stored on SharedState.
        def config_fallback
          SharedState
        end

        def multistore
          MultiStore.create_using_pool(MemoryStoreTraceChunks.pool, pool, store_name)
        end
      end
    end
  end
end
