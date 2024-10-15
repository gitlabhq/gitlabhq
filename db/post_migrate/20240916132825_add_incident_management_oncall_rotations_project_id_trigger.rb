# frozen_string_literal: true

class AddIncidentManagementOncallRotationsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :incident_management_oncall_rotations,
      sharding_key: :project_id,
      parent_table: :incident_management_oncall_schedules,
      parent_sharding_key: :project_id,
      foreign_key: :oncall_schedule_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :incident_management_oncall_rotations,
      sharding_key: :project_id,
      parent_table: :incident_management_oncall_schedules,
      parent_sharding_key: :project_id,
      foreign_key: :oncall_schedule_id
    )
  end
end
