# frozen_string_literal: true

class AddProjectIdToIncidentManagementOncallRotations < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :incident_management_oncall_rotations, :project_id, :bigint
  end
end
