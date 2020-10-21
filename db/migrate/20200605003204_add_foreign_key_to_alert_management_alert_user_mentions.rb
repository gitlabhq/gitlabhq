# frozen_string_literal: true

class AddForeignKeyToAlertManagementAlertUserMentions < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :alert_management_alert_user_mentions, :notes, column: :note_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :alert_management_alert_user_mentions, column: :note_id
    end
  end
end
