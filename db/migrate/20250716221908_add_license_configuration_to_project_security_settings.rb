# frozen_string_literal: true

class AddLicenseConfigurationToProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    add_column :project_security_settings, :license_configuration_source, :smallint, default: 0, null: false
  end

  def down
    remove_column :project_security_settings, :license_configuration_source
  end
end
