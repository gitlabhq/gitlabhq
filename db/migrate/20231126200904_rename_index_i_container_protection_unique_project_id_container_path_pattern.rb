# frozen_string_literal: true

class RenameIndexIContainerProtectionUniqueProjectIdContainerPathPattern < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    rename_index :container_registry_protection_rules, :idx_copy_d01a85dee8,
      :i_container_protection_unique_project_repository_path_pattern
  end

  def down
    rename_index :container_registry_protection_rules, :i_container_protection_unique_project_repository_path_pattern,
      :idx_copy_d01a85dee8
  end
end
