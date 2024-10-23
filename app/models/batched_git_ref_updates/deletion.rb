# frozen_string_literal: true

module BatchedGitRefUpdates
  class Deletion < ApplicationRecord
    PARTITION_DURATION = 1.day

    include BulkInsertSafe
    include PartitionedTable
    include EachBatch

    self.table_name = 'p_batched_git_ref_updates_deletions'
    self.primary_key = :id
    self.sequence_name = :to_be_deleted_git_refs_id_seq

    # This column must be ignored otherwise Rails will cache the default value and `bulk_insert!` will start saving
    # incorrect partition_id.
    ignore_column :partition_id, remove_never: true

    belongs_to :project, inverse_of: :to_be_deleted_git_refs

    scope :for_partition, ->(partition) { where(partition_id: partition) }
    scope :for_project, ->(project_id) { where(project_id: project_id) }
    scope :select_ref_and_identity, -> { select(:ref, :id, arel_table[:partition_id].as('partition')) }

    partitioned_by :partition_id, strategy: :sliding_list,
      next_partition_if: ->(active_partition) do
        oldest_record_in_partition = Deletion
          .select(:id, :created_at)
          .for_partition(active_partition.value)
          .order(:id)
          .limit(1)
          .take

        oldest_record_in_partition.present? &&
          oldest_record_in_partition.created_at < PARTITION_DURATION.ago
      end,
      detach_partition_if: ->(partition) do
        !Deletion
          .for_partition(partition.value)
          .status_pending
          .exists?
      end

    enum status: { pending: 1, processed: 2 }, _prefix: :status

    def self.mark_records_processed(records)
      update_by_partition(records) do |partitioned_scope|
        partitioned_scope.update_all(status: :processed)
      end
    end

    # Your scope must select_ref_and_identity before calling this method as it relies on partition being explicitly
    # selected
    def self.update_by_partition(records)
      records.group_by(&:partition).each do |partition, records_within_partition|
        partitioned_scope = status_pending
          .for_partition(partition)
          .where(id: records_within_partition.map(&:id))

        yield(partitioned_scope)
      end
    end

    private_class_method :update_by_partition
  end
end
