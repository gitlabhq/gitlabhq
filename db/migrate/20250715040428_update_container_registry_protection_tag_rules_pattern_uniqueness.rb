# frozen_string_literal: true

class UpdateContainerRegistryProtectionTagRulesPatternUniqueness < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  TABLE_NAME = :container_registry_protection_tag_rules
  UNIQUE_INDEX_NAME = :unique_protection_tag_rules_project_id_and_tag_name_pattern
  IMMUTABLE_INDEX_NAME = :unique_protection_tag_rules_immutable
  MUTABLE_INDEX_NAME = :unique_protection_tag_rules_mutable

  def up
    # Unique index for immutable rules
    add_concurrent_index TABLE_NAME,
      [:project_id, :tag_name_pattern],
      unique: true,
      where: 'minimum_access_level_for_push IS NULL AND minimum_access_level_for_delete IS NULL',
      name: IMMUTABLE_INDEX_NAME

    # Unique index for mutable rules
    add_concurrent_index TABLE_NAME,
      [:project_id, :tag_name_pattern],
      unique: true,
      where: 'minimum_access_level_for_push IS NOT NULL AND minimum_access_level_for_delete IS NOT NULL',
      name: MUTABLE_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, name: UNIQUE_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME,
      [:project_id, :tag_name_pattern],
      unique: true,
      name: UNIQUE_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, name: IMMUTABLE_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, name: MUTABLE_INDEX_NAME
  end
end
