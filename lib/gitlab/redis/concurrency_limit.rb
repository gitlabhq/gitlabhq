# frozen_string_literal: true

module Gitlab
  module Redis
    class ConcurrencyLimit < ::Gitlab::Redis::Wrapper
      def self.config_fallback
        SharedState
      end
    end
  end
end
