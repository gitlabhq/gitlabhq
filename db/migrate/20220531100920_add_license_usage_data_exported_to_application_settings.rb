# frozen_string_literal: true

class AddLicenseUsageDataExportedToApplicationSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :application_settings, :license_usage_data_exported, :boolean, default: false, null: false
  end
end
