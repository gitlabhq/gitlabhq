# frozen_string_literal: true

class AddProjectsParentFkToMergeRequestsMergeData < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.5'

  TABLE_NAME = :merge_requests_merge_data

  def up
    # NOTE: Foreign keys on partitions have already been created and validated asynchronously in 18.4.
    #  This migration adds foreign keys to the main partitioned tables.
    add_concurrent_partitioned_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    # NOTE: Dropping foreign keys on the parent partitioned table will also remove foreign keys on partitions
    #   which we created and validated asynchronously
    with_lock_retries do
      remove_foreign_key TABLE_NAME, column: :project_id
    end
  end
end
