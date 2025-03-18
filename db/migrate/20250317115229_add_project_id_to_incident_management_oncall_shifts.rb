# frozen_string_literal: true

class AddProjectIdToIncidentManagementOncallShifts < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :incident_management_oncall_shifts, :project_id, :bigint
  end
end
