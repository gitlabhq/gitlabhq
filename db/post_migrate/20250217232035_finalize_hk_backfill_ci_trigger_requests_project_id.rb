# frozen_string_literal: true

class FinalizeHkBackfillCiTriggerRequestsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiTriggerRequestsProjectId',
      table_name: :ci_trigger_requests,
      column_name: :id,
      job_arguments: [:project_id, :ci_triggers, :project_id, :trigger_id],
      finalize: true
    )
  end

  def down; end
end
