# frozen_string_literal: true

class CreateAlertManagementAlertUserMentions < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :alert_management_alert_user_mentions do |t|
      t.references :alert_management_alert, type: :bigint, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :note_id, null: true

      t.integer    :mentioned_users_ids, array: true
      t.integer    :mentioned_projects_ids, array: true
      t.integer    :mentioned_groups_ids, array: true
    end

    add_index :alert_management_alert_user_mentions, [:note_id], where: 'note_id IS NOT NULL', unique: true, name: 'index_alert_user_mentions_on_note_id'
    add_index :alert_management_alert_user_mentions, [:alert_management_alert_id], where: 'note_id IS NULL', unique: true, name: 'index_alert_user_mentions_on_alert_id'
    add_index :alert_management_alert_user_mentions, [:alert_management_alert_id, :note_id], unique: true, name: 'index_alert_user_mentions_on_alert_id_and_note_id'
  end
end
