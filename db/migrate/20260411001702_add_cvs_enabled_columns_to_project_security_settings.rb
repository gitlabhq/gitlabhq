# frozen_string_literal: true

class AddCvsEnabledColumnsToProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :project_security_settings, :cvs_for_container_scanning_enabled, :boolean, default: true, null: false
    add_column :project_security_settings, :cvs_for_dependency_scanning_enabled, :boolean, default: true, null: false
  end

  def down
    remove_column :project_security_settings, :cvs_for_container_scanning_enabled
    remove_column :project_security_settings, :cvs_for_dependency_scanning_enabled
  end
end
