# frozen_string_literal: true

class AddApproverToNotificationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  enable_lock_retries!

  def change
    add_column :notification_settings, :approver, :boolean, default: false, null: false
  end
end
