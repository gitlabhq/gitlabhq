# frozen_string_literal: true

class AddLicenseScanningForCyclonedxEnabledToProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :project_security_settings, :license_scanning_for_cyclonedx_enabled, :boolean, default: true, null: false
  end

  def down
    remove_column :project_security_settings, :license_scanning_for_cyclonedx_enabled
  end
end
