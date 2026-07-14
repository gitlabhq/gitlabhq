# frozen_string_literal: true

class AddForeignKeyForDuoDependencyBumpBreakingChangesEnabledBy < Gitlab::Database::Migration[2.3]
  milestone '19.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_settings, :users,
      column: :duo_dependency_bump_breaking_changes_enabled_by_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_settings, column: :duo_dependency_bump_breaking_changes_enabled_by_id
    end
  end
end
