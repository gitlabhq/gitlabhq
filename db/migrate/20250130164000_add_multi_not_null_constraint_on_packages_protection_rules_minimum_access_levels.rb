# frozen_string_literal: true

class AddMultiNotNullConstraintOnPackagesProtectionRulesMinimumAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  TABLE_NAME = :packages_protection_rules

  def up
    add_multi_column_not_null_constraint(TABLE_NAME,
      :minimum_access_level_for_push,
      :minimum_access_level_for_delete,
      operator: '>',
      limit: 0
    )
  end

  def down
    remove_multi_column_not_null_constraint(TABLE_NAME,
      :minimum_access_level_for_push,
      :minimum_access_level_for_delete
    )
  end
end
