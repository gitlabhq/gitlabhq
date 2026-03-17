# frozen_string_literal: true

class FinalizeBackfillMergeRequestFileDiffsPartitionedTable < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMergeRequestFileDiffsPartitionedTable',
      table_name: :merge_request_diff_files,
      column_name: :merge_request_diff_id,
      job_arguments: [:merge_request_diff_files_99208b8fac, :merge_request_diff_id, :relative_order],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
