# frozen_string_literal: true

module Gitlab
  module Redis
    class SidekiqStatusMigrator < ::Gitlab::Redis::MultiStoreWrapper
      class << self
        def multistore
          # migrate from SharedState to QueuesMetadata
          MultiStore.new(QueuesMetadata.pool, SharedState.pool, store_name)
        end
      end
    end
  end
end
