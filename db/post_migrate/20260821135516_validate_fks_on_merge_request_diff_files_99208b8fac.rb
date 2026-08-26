# frozen_string_literal: true

class ValidateFksOnMergeRequestDiffFiles99208b8fac < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.4'
  disable_ddl_transaction!

  TABLE_NAME = :merge_request_diff_files_99208b8fac
  FK_PROJECT_ID = :fk_rails_ebcce501f5
  FK_MR_DIFF_ID = :fk_rails_6fff895059

  def up
    # These FKs were added with validate: false in 20260526222208 and
    # validated asynchronously on GitLab.com. This migration validates
    # the FKs on all partitions and adds them to the parent partitioned
    # table, ensuring new partitions inherit the constraints.
    add_concurrent_partitioned_foreign_key(
      TABLE_NAME, :projects,
      column: :project_id,
      name: FK_PROJECT_ID,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
    )

    add_concurrent_partitioned_foreign_key(
      TABLE_NAME, :merge_request_diffs,
      column: :merge_request_diff_id,
      name: FK_MR_DIFF_ID,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
    )
  end

  def down
    # no-op
  end
end
