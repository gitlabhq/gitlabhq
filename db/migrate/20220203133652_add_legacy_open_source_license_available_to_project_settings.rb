# frozen_string_literal: true

class AddLegacyOpenSourceLicenseAvailableToProjectSettings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :project_settings, :legacy_open_source_license_available, :boolean, default: true, null: false
  end
end
