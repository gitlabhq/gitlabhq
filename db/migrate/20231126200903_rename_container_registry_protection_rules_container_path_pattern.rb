# frozen_string_literal: true

class RenameContainerRegistryProtectionRulesContainerPathPattern < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    rename_column_concurrently :container_registry_protection_rules, :container_path_pattern, :repository_path_pattern
  end

  def down
    undo_rename_column_concurrently :container_registry_protection_rules, :container_path_pattern,
      :repository_path_pattern
  end
end
