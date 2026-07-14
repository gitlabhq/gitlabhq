# frozen_string_literal: true

class AddDuoDependencyBumpBreakingChangesEnabledByToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :project_settings, :duo_dependency_bump_breaking_changes_enabled_by_id, :bigint
  end
end
