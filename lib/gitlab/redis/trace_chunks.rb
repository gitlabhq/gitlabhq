# frozen_string_literal: true

module Gitlab
  module Redis
    class TraceChunks < ::Gitlab::Redis::Wrapper
      # The data we store on TraceChunks used to be stored on SharedState.
      def self.config_fallback
        SharedState
      end
    end
  end
end
