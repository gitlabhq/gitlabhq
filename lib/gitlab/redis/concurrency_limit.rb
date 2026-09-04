# frozen_string_literal: true

module Gitlab
  module Redis
    class ConcurrencyLimit < ::Gitlab::Redis::MultiStoreWrapper
      def self.config_fallback
        SharedState
      end

      def self.multistore
        MultiStore.create_using_pool(pool, SharedState.pool, store_name)
      end
    end
  end
end
