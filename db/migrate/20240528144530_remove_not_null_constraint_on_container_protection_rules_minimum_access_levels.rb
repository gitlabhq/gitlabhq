# frozen_string_literal: true

class RemoveNotNullConstraintOnContainerProtectionRulesMinimumAccessLevels < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  TABLE_NAME = :container_registry_protection_rules

  def up
    remove_not_null_constraint TABLE_NAME, :minimum_access_level_for_push
    remove_not_null_constraint TABLE_NAME, :minimum_access_level_for_delete
  end

  def down
    add_not_null_constraint TABLE_NAME, :minimum_access_level_for_push
    add_not_null_constraint TABLE_NAME, :minimum_access_level_for_delete
  end
end
