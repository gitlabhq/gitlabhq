# frozen_string_literal: true

class AddForeignKeyToUserIdOnAlertManagementAlertAssignees < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :alert_management_alert_assignees, :users, column: :user_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :alert_management_alert_assignees, column: :user_id
    end
  end
end
