# frozen_string_literal: true

class AddProjectIdToAlertManagementAlertAssignees < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column :alert_management_alert_assignees, :project_id, :bigint
  end
end
