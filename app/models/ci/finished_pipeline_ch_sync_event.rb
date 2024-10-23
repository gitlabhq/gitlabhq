# frozen_string_literal: true

module Ci
  class FinishedPipelineChSyncEvent < Ci::ApplicationRecord
    include EachBatch
    include FromUnion
    include PartitionedTable

    PARTITION_DURATION = 1.day
    PARTITION_CLEANUP_THRESHOLD = 30.days

    self.table_name = :p_ci_finished_pipeline_ch_sync_events
    self.primary_key = :pipeline_id

    ignore_columns :partition, remove_never: true

    partitioned_by :partition, strategy: :sliding_list,
      next_partition_if: ->(active_partition) { any_older_partitions_exist?(active_partition, PARTITION_DURATION) },
      detach_partition_if: ->(partition) { detach_partition?(partition) }

    validates :pipeline_id, presence: true
    validates :pipeline_finished_at, presence: true
    validates :project_namespace_id, presence: true

    scope :order_by_pipeline_id, -> do
      keyset_aware_order = Gitlab::Pagination::Keyset::Order.build([
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'pipeline_id',
          order_expression: Ci::FinishedPipelineChSyncEvent.arel_table[:pipeline_id].asc,
          nullable: :not_nullable
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'project_namespace_id',
          order_expression: Ci::FinishedPipelineChSyncEvent.arel_table[:project_namespace_id].asc,
          nullable: :not_nullable
        )
      ])

      order(keyset_aware_order)
    end

    scope :pending, -> { where(processed: false) }
    scope :for_partition, ->(partition) { where(partition: partition) }

    def self.detach_partition?(partition)
      # detach partition if there are no pending events in partition
      return true unless pending.for_partition(partition.value).exists?

      # or if there are pending events, they are outside the cleanup threshold
      return true unless any_newer_partitions_exist?(partition, PARTITION_CLEANUP_THRESHOLD)

      false
    end

    def self.any_older_partitions_exist?(partition, duration)
      for_partition(partition.value)
        .where(arel_table[:pipeline_finished_at].lteq(duration.ago))
        .exists?
    end

    def self.any_newer_partitions_exist?(partition, duration)
      for_partition(partition.value)
        .where(arel_table[:pipeline_finished_at].gt(duration.ago))
        .exists?
    end
  end
end
