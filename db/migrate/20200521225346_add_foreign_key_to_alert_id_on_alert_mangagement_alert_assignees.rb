# frozen_string_literal: true

class AddForeignKeyToAlertIdOnAlertMangagementAlertAssignees < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :alert_management_alert_assignees, :alert_management_alerts, column: :alert_id, on_delete: :cascade # rubocop:disable Migration/AddConcurrentForeignKey
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :alert_management_alert_assignees, column: :alert_id
    end
  end
end
