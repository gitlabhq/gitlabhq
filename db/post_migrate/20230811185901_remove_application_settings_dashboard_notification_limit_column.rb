# frozen_string_literal: true

class RemoveApplicationSettingsDashboardNotificationLimitColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :application_settings, :dashboard_notification_limit, :integer, default: 0, null: false
  end
end
