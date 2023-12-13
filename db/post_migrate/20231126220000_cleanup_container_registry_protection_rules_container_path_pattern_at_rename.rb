# frozen_string_literal: true

class CleanupContainerRegistryProtectionRulesContainerPathPatternAtRename < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :container_registry_protection_rules, :container_path_pattern,
      :repository_path_pattern
  end

  def down
    undo_cleanup_concurrent_column_rename :container_registry_protection_rules, :container_path_pattern,
      :repository_path_pattern

    # Restoring the old index name `:i_container_protection_unique_project_id_container_path_pattern`
    # that was changed in the following migrations:
    # - `db/migrate/20231126200903_rename_container_registry_protection_rules_container_path_pattern.rb`
    # - `db/migrate/20231126200904_rename_index_i_container_protection_unique_project_id_container_path_pattern.rb`
    if index_exists?(:container_registry_protection_rules, [:project_id, :container_path_pattern],
      name: :i_container_protection_unique_project_container_path_pattern)
      rename_index :container_registry_protection_rules, :i_container_protection_unique_project_container_path_pattern,
        :i_container_protection_unique_project_id_container_path_pattern
    end
  end
end
