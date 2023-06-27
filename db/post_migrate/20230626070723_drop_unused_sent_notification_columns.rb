# frozen_string_literal: true

class DropUnusedSentNotificationColumns < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :sent_notifications, :line_code
    remove_column :sent_notifications, :note_type
    remove_column :sent_notifications, :position
  end

  def down
    add_column :sent_notifications, :line_code, :string
    add_column :sent_notifications, :note_type, :string
    add_column :sent_notifications, :position, :text
  end
end
