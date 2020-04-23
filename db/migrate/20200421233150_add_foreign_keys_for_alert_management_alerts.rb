# frozen_string_literal: true

class AddForeignKeysForAlertManagementAlerts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :alert_management_alerts, :projects, column: :project_id, on_delete: :cascade
    add_concurrent_foreign_key :alert_management_alerts, :issues, column: :issue_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :alert_management_alerts, column: :project_id
    remove_foreign_key_if_exists :alert_management_alerts, column: :issue_id
  end
end
