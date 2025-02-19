# frozen_string_literal: true

class RemoveNotNullConstraintFromMininumAccessLevelForPush < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    remove_not_null_constraint :packages_protection_rules, :minimum_access_level_for_push
  end

  def down
    add_not_null_constraint :packages_protection_rules, :minimum_access_level_for_push
  end
end
