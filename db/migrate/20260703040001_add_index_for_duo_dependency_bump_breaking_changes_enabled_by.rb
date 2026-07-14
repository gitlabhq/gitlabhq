# frozen_string_literal: true

class AddIndexForDuoDependencyBumpBreakingChangesEnabledBy < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  INDEX_NAME = 'idx_project_settings_on_duo_dep_bump_bc_enabled_by_id'

  def up
    add_concurrent_index :project_settings, :duo_dependency_bump_breaking_changes_enabled_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :project_settings, INDEX_NAME
  end
end
