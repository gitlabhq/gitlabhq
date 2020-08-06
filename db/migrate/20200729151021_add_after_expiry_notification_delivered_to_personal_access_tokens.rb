# frozen_string_literal: true

class AddAfterExpiryNotificationDeliveredToPersonalAccessTokens < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :personal_access_tokens, :after_expiry_notification_delivered, :boolean, null: false, default: false
  end
end
