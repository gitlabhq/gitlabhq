# frozen_string_literal: true

class AddCloudLicenseEnabledToSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :cloud_license_enabled, :boolean, null: false, default: false
  end
end
