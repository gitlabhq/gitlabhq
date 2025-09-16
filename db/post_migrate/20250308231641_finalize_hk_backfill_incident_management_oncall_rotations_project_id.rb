# frozen_string_literal: true

class FinalizeHkBackfillIncidentManagementOncallRotationsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIncidentManagementOncallRotationsProjectId',
      table_name: :incident_management_oncall_rotations,
      column_name: :id,
      job_arguments: [:project_id, :incident_management_oncall_schedules, :project_id, :oncall_schedule_id],
      finalize: true
    )
  end

  def down; end
end
