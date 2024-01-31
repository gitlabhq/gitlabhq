# frozen_string_literal: true

class RemoveNotNullConstraintFromPackageNamePatternIlikeQueryColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  def up
    change_column_null :packages_protection_rules, :package_name_pattern_ilike_query, true
  end

  def down
    change_column_null :packages_protection_rules, :package_name_pattern_ilike_query, false
  end
end
