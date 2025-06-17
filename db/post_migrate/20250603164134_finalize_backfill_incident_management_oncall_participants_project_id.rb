# frozen_string_literal: true

class FinalizeBackfillIncidentManagementOncallParticipantsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillIncidentManagementOncallParticipantsProjectId',
      table_name: :incident_management_oncall_participants,
      column_name: :id,
      job_arguments: [:project_id, :incident_management_oncall_rotations, :project_id, :oncall_rotation_id],
      finalize: true
    )
  end

  def down
    # This is an empty down migration.
    # Batched background migrations are not reversed automatically.
  end
end
