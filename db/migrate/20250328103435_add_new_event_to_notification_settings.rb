# frozen_string_literal: true

class AddNewEventToNotificationSettings < Gitlab::Database::Migration[2.2]
  milestone '18.1'

  def change
    add_column :notification_settings, :service_account_failed_pipeline, :boolean, null: false, default: false,
      if_not_exists: true
    add_column :notification_settings, :service_account_success_pipeline, :boolean, null: false, default: false,
      if_not_exists: true
    add_column :notification_settings, :service_account_fixed_pipeline, :boolean, null: false, default: false,
      if_not_exists: true
  end
end
