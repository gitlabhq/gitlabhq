# frozen_string_literal: true

class RemovePackagesProtectionRulesPackageNamePatternIlikeQueryColumn < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  def up
    if column_exists?(
      :packages_protection_rules, :package_name_pattern_ilike_query)
      with_lock_retries do
        remove_column :packages_protection_rules, :package_name_pattern_ilike_query
      end
    end
  end

  def down
    with_lock_retries do
      unless column_exists?(
        :packages_protection_rules, :package_name_pattern_ilike_query)
        add_column :packages_protection_rules, :package_name_pattern_ilike_query, :text
      end
    end

    add_text_limit :packages_protection_rules, :package_name_pattern_ilike_query, 255
  end
end
