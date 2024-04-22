# frozen_string_literal: true

class CleanupContainerRegistryProtectionRuleProtectedUpToAccessLevelsRename < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  TABLE = :container_registry_protection_rules

  def up
    cleanup_concurrent_column_rename TABLE, :push_protected_up_to_access_level, :minimum_access_level_for_push
    cleanup_concurrent_column_rename TABLE, :delete_protected_up_to_access_level, :minimum_access_level_for_delete
  end

  def down
    undo_cleanup_concurrent_column_rename TABLE, :push_protected_up_to_access_level, :minimum_access_level_for_push
    undo_cleanup_concurrent_column_rename TABLE, :delete_protected_up_to_access_level, :minimum_access_level_for_delete
  end
end
