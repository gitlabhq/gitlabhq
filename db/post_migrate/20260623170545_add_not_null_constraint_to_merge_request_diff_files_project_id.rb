# frozen_string_literal: true

class AddNotNullConstraintToMergeRequestDiffFilesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  # Only add the constraint to the partitioned table. The original table has ~13.7B rows
  # with NULL project_id (legacy data never backfilled). The backfill migration
  # (BackfillMergeRequestFileDiffsPartitionedTable) INSERTs into the partitioned table
  # with project_id populated via COALESCE, but does not UPDATE the original table.
  #
  # The original table will be swapped out and archived in a subsequent migration
  # (!241924), so there's no value in backfilling it. New rows ARE getting project_id
  # populated via the MergeRequestDiffFile#update_project_id callback.
  #
  # Using validate: false because the table is large (~3 hours to validate).
  # Async validation is prepared in the next migration.
  def up
    add_not_null_constraint :merge_request_diff_files_99208b8fac, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :merge_request_diff_files_99208b8fac, :project_id
  end
end
