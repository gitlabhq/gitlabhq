# frozen_string_literal: true

class RenameContainerProtectionRulesProtectedAccessLevelToMinimumAccessLevel < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  TABLE = :container_registry_protection_rules

  def up
    rename_column_concurrently TABLE, :push_protected_up_to_access_level, :minimum_access_level_for_push
    rename_column_concurrently TABLE, :delete_protected_up_to_access_level, :minimum_access_level_for_delete
  end

  def down
    undo_rename_column_concurrently TABLE, :push_protected_up_to_access_level, :minimum_access_level_for_push
    undo_rename_column_concurrently TABLE, :delete_protected_up_to_access_level, :minimum_access_level_for_delete
  end
end
