# frozen_string_literal: true

class AddFastDependencyPathsEnabledToProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    add_column :project_security_settings, :fast_dependency_paths_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :project_security_settings, :fast_dependency_paths_enabled
  end
end
