# frozen_string_literal: true

class AddIncidentManagementOncallParticipantsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :incident_management_oncall_participants,
      sharding_key: :project_id,
      parent_table: :incident_management_oncall_rotations,
      parent_sharding_key: :project_id,
      foreign_key: :oncall_rotation_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :incident_management_oncall_participants,
      sharding_key: :project_id,
      parent_table: :incident_management_oncall_rotations,
      parent_sharding_key: :project_id,
      foreign_key: :oncall_rotation_id
    )
  end
end
