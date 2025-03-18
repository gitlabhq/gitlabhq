# frozen_string_literal: true

class FinalizeHkBackfillMergeRequestUserMentionsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillMergeRequestUserMentionsProjectId',
      table_name: :merge_request_user_mentions,
      column_name: :id,
      job_arguments: [:project_id, :merge_requests, :target_project_id, :merge_request_id],
      finalize: true
    )
  end

  def down; end
end
