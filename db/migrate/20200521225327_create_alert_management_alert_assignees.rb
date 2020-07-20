# frozen_string_literal: true

class CreateAlertManagementAlertAssignees < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  ALERT_INDEX_NAME = 'index_alert_assignees_on_alert_id'
  UNIQUE_INDEX_NAME = 'index_alert_assignees_on_user_id_and_alert_id'

  def up
    create_table :alert_management_alert_assignees do |t|
      t.bigint :user_id, null: false
      t.bigint :alert_id, null: false

      t.index :alert_id, name: ALERT_INDEX_NAME
      t.index [:user_id, :alert_id], unique: true, name: UNIQUE_INDEX_NAME
    end
  end

  def down
    drop_table :alert_management_alert_assignees
  end
end
