# frozen_string_literal: true

module Gitlab
  module Redis
    class Sessions < ::Gitlab::Redis::Wrapper
      # The data we store on Sessions used to be stored on SharedState.
      def self.config_fallback
        SharedState
      end
    end
  end
end
