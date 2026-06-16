# frozen_string_literal: true

class TightenShardingKeyConstraintOnDependencyListExports < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.11'

  TABLE_NAME = :dependency_list_exports
  COLUMNS = %i[group_id organization_id project_id].freeze
  # The auto-generated name for `add_multi_column_not_null_constraint` on these
  # columns happens to collide with the existing `> 0` constraint name. Use an
  # explicit name for the new `= 1` constraint so both can coexist briefly while
  # the old one is dropped, leaving the table with a sharding-key constraint at
  # all times.
  NEW_CONSTRAINT_NAME = 'check_dependency_list_exports_sharding_key_eq_1'
  OLD_CONSTRAINT_NAME = 'check_67a9c23e79'

  def up
    # Add the stricter `= 1` constraint first. Production data verified to have 0
    # violations on postgres.ai (see parent issue), so we can add it as valid.
    add_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, constraint_name: NEW_CONSTRAINT_NAME)

    # Drop the old `> 0` constraint that allowed more than one sharding key to be set.
    remove_check_constraint(TABLE_NAME, OLD_CONSTRAINT_NAME)
  end

  def down
    add_check_constraint(
      TABLE_NAME,
      "num_nonnulls(group_id, organization_id, project_id) > 0",
      OLD_CONSTRAINT_NAME
    )

    remove_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, constraint_name: NEW_CONSTRAINT_NAME)
  end
end
