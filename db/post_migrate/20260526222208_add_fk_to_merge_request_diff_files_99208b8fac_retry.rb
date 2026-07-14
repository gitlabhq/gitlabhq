# frozen_string_literal: true

class AddFkToMergeRequestDiffFiles99208b8facRetry < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.1'

  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  FK_PROJECT_ID = :fk_rails_ebcce501f5
  FK_MR_DIFF_ID = :fk_rails_6fff895059

  def up
    add_concurrent_partitioned_foreign_key(
      TABLE_NAME, :projects,
      column: :project_id,
      on_delete: :cascade,
      validate: false
    )

    add_concurrent_partitioned_foreign_key(
      TABLE_NAME, :merge_request_diffs,
      column: :merge_request_diff_id,
      on_delete: :cascade,
      validate: false
    )

    # Prepare async validation immediately after adding FKs to ensure all
    # partitions that have the FK are scheduled for validation
    prepare_partitioned_async_foreign_key_validation TABLE_NAME, :project_id, name: FK_PROJECT_ID
    prepare_partitioned_async_foreign_key_validation TABLE_NAME, :merge_request_diff_id, name: FK_MR_DIFF_ID
  end

  def down
    unprepare_partitioned_async_foreign_key_validation TABLE_NAME, :project_id, name: FK_PROJECT_ID
    unprepare_partitioned_async_foreign_key_validation TABLE_NAME, :merge_request_diff_id, name: FK_MR_DIFF_ID

    remove_partitioned_foreign_key(
      TABLE_NAME,
      :projects,
      column: :project_id
    )

    remove_partitioned_foreign_key(
      TABLE_NAME,
      :merge_request_diffs,
      column: :merge_request_diff_id
    )
  end
end
