# frozen_string_literal: true

class AddBeforeExpiryNotificationDeliveredToKeys < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :keys, :before_expiry_notification_delivered_at, :datetime_with_timezone
  end
end
