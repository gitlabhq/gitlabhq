# frozen_string_literal: true

class AddNewUniqueIndexToPackagesProtectionRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.9'

  INDEX_NAME = 'i_packages_unique_project_package_type_target_pattern'

  def up
    add_concurrent_index :packages_protection_rules,
      [:project_id, :package_type, :target_field, :pattern_type, :pattern],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_protection_rules, INDEX_NAME
  end
end
