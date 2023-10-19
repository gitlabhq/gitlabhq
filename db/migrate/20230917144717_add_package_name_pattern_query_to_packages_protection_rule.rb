# frozen_string_literal: true

class AddPackageNamePatternQueryToPackagesProtectionRule < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless column_exists?(
        :packages_protection_rules, :package_name_pattern_ilike_query)
        # rubocop:disable Rails/NotNullColumn
        add_column :packages_protection_rules, :package_name_pattern_ilike_query, :text, null: false
        # rubocop:enable Rails/NotNullColumn
      end
    end

    add_text_limit :packages_protection_rules, :package_name_pattern_ilike_query, 255
  end

  def down
    remove_column :packages_protection_rules, :package_name_pattern_ilike_query
  end
end
