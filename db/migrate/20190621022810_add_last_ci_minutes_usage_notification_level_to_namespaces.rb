# frozen_string_literal: true

class AddLastCiMinutesUsageNotificationLevelToNamespaces < ActiveRecord::Migration[5.1]
  DOWNTIME = false

  def change
    add_column :namespaces, :last_ci_minutes_usage_notification_level, :integer
  end
end
