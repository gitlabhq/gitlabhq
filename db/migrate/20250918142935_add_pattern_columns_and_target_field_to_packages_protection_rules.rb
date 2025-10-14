# frozen_string_literal: true

class AddPatternColumnsAndTargetFieldToPackagesProtectionRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  def up
    with_lock_retries do
      add_column :packages_protection_rules, :pattern, :text, if_not_exists: true
      add_column :packages_protection_rules, :pattern_type, :integer, limit: 2, default: 0, null: false,
        if_not_exists: true
      add_column :packages_protection_rules, :target_field, :integer, limit: 2, default: 0, null: false,
        if_not_exists: true
    end

    add_text_limit :packages_protection_rules, :pattern, 255
  end

  def down
    with_lock_retries do
      remove_column :packages_protection_rules, :pattern, if_exists: true
      remove_column :packages_protection_rules, :pattern_type, if_exists: true
      remove_column :packages_protection_rules, :target_field, if_exists: true
    end
  end
end
