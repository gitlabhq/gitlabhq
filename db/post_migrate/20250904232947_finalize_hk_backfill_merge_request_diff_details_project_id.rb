# frozen_string_literal: true

class FinalizeHkBackfillMergeRequestDiffDetailsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMergeRequestDiffDetailsProjectId',
      table_name: :merge_request_diff_details,
      column_name: :merge_request_diff_id,
      job_arguments: [:project_id, :merge_request_diffs, :project_id, :merge_request_diff_id],
      finalize: true
    )
  end

  def down; end
end
