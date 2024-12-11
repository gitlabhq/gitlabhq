# frozen_string_literal: true

class AddIndexContainerRegistryProtectionTagRulesOnMinAccessLevel < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  INDEX_NAME = :idx_container_registry_protection_tag_rules_on_min_access_level
  COLUMN_NAMES = %i[project_id minimum_access_level_for_push minimum_access_level_for_delete]

  def up
    add_concurrent_index :container_registry_protection_tag_rules, COLUMN_NAMES, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_registry_protection_tag_rules, INDEX_NAME
  end
end
