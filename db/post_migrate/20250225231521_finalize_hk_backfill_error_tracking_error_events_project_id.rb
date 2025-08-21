# frozen_string_literal: true

class FinalizeHkBackfillErrorTrackingErrorEventsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillErrorTrackingErrorEventsProjectId',
      table_name: :error_tracking_error_events,
      column_name: :id,
      job_arguments: [:project_id, :error_tracking_errors, :project_id, :error_id],
      finalize: true
    )
  end

  def down; end
end
