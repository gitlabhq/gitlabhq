# frozen_string_literal: true

class CreateIndexAlertManagementAlertsOnCreatedAtProjectIdWithIssue < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'idx_alert_management_alerts_on_created_at_project_id_with_issue'

  disable_ddl_transaction!

  def up
    add_concurrent_index :alert_management_alerts, [:created_at, :project_id],
      where: 'issue_id IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :alert_management_alerts, INDEX_NAME
  end
end
