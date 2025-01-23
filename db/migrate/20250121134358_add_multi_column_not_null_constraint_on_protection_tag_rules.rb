# frozen_string_literal: true

class AddMultiColumnNotNullConstraintOnProtectionTagRules < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_multi_column_not_null_constraint(
      :container_registry_protection_tag_rules,
      :minimum_access_level_for_push,
      :minimum_access_level_for_delete,
      operator: '!=',
      limit: 1
    )
  end

  def down
    remove_multi_column_not_null_constraint(:container_registry_protection_tag_rules,
      :minimum_access_level_for_push,
      :minimum_access_level_for_delete)
  end
end
