# frozen_string_literal: true

module Gitlab
  module Redis
    class MemoryStoreTraceChunks < ::Gitlab::Redis::Wrapper
      # The data we store on TraceChunks used to be stored on SharedState.
      class << self
        def config_fallback
          SharedState
        end
      end
    end
  end
end
