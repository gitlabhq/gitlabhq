# frozen_string_literal: true

class IndexAlertManagementAlertAssigneesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_alert_management_alert_assignees_on_project_id'

  def up
    add_concurrent_index :alert_management_alert_assignees, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :alert_management_alert_assignees, INDEX_NAME
  end
end
