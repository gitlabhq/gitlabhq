# frozen_string_literal: true

module Ci
  class FinishedPipelineChSyncEvent < Ci::ApplicationRecord
    include EachBatch
    include FromUnion
    include IgnorableColumns
    include PartitionedTable

    PARTITION_DURATION = 1.day
    PARTITION_CLEANUP_THRESHOLD = 30.days

    self.table_name = :p_ci_finished_pipeline_ch_sync_events
    self.primary_key = :pipeline_id

    ignore_columns :partition, remove_never: true

    partitioned_by :partition, strategy: :sliding_list,
      next_partition_if: ->(active_partition) do
        next_partition_if(active_partition)
      end,
      detach_partition_if: ->(partition) do
        detach_partition?(partition)
      end

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

    def self.next_partition_if(active_partition)
      oldest_record_in_partition = FinishedPipelineChSyncEvent.for_partition(active_partition.value)
        .order(:pipeline_finished_at).first

      oldest_record_in_partition.present? &&
        oldest_record_in_partition.pipeline_finished_at < PARTITION_DURATION.ago
    end

    def self.detach_partition?(partition)
      # if there are no pending events
      return true unless FinishedPipelineChSyncEvent.pending.for_partition(partition.value).exists?

      # if partition only has the very old data
      newest_record_in_partition = FinishedPipelineChSyncEvent.for_partition(partition.value)
        .order(:pipeline_finished_at).last

      newest_record_in_partition.present? &&
        newest_record_in_partition.pipeline_finished_at < PARTITION_CLEANUP_THRESHOLD.ago
    end
  end
end
