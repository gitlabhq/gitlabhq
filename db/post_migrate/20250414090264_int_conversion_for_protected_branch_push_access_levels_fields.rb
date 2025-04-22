# frozen_string_literal: true

class IntConversionForProtectedBranchPushAccessLevelsFields < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  TABLE = :protected_branch_push_access_levels
  COLUMNS = %i[id protected_branch_id user_id group_id deploy_key_id]

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
