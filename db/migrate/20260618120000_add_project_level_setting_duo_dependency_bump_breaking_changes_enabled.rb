# frozen_string_literal: true

class AddProjectLevelSettingDuoDependencyBumpBreakingChangesEnabled < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :project_settings, :duo_dependency_bump_breaking_changes_enabled, :boolean, default: false, null: false
  end
end
