# frozen_string_literal: true

class AddExpiryNotificationDeliveredToKeys < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :keys, :expiry_notification_delivered_at, :datetime_with_timezone
  end
end
