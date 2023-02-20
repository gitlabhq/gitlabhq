# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This rebalances partition_id to fix invalid records in production
    class RebalancePartitionId < BatchedMigrationJob
      INVALID_PARTITION_ID = 101
      VALID_PARTITION_ID = 100

      scope_to ->(relation) { relation.where(partition_id: INVALID_PARTITION_ID) }
      operation_name :update_all
      feature_category :continuous_integration

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(partition_id: VALID_PARTITION_ID)
        end
      end
    end
  end
end
