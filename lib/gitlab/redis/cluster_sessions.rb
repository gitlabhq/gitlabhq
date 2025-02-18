# frozen_string_literal: true

module Gitlab
  module Redis
    class ClusterSessions < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on Sessions used to be stored on SharedState.
        def config_fallback
          SharedState
        end
      end
    end
  end
end
