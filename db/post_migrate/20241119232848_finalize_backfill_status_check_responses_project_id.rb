# frozen_string_literal: true

class FinalizeBackfillStatusCheckResponsesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillStatusCheckResponsesProjectId',
      table_name: :status_check_responses,
      column_name: :id,
      job_arguments: [:project_id, :merge_requests, :target_project_id, :merge_request_id],
      finalize: true
    )
  end

  def down; end
end
