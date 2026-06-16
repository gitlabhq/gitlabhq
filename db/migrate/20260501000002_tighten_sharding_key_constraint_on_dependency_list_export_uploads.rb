# frozen_string_literal: true

class TightenShardingKeyConstraintOnDependencyListExportUploads < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  TABLE_NAME = :dependency_list_export_uploads
  COLUMNS = %i[namespace_id organization_id project_id].freeze
  OLD_CONSTRAINT_NAME = 'check_889220aa2d'
  # Use an explicit name so we don't collide with the auto-generated name for
  # the existing `> 0` constraint, which is also based on the same columns.
  NEW_CONSTRAINT_NAME = 'check_dependency_list_export_uploads_sharding_key_eq_1'

  def up
    # Add the stricter `= 1` constraint first. Production data verified to have
    # 0 violations on postgres.ai (see https://gitlab.com/gitlab-org/gitlab/-/work_items/597554),
    # so we can add it as valid.
    add_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, constraint_name: NEW_CONSTRAINT_NAME)

    # Drop the old `> 0` constraint that allowed more than one sharding key to be set.
    remove_check_constraint(TABLE_NAME, OLD_CONSTRAINT_NAME)
  end

  def down
    add_check_constraint(
      TABLE_NAME,
      "num_nonnulls(namespace_id, organization_id, project_id) > 0",
      OLD_CONSTRAINT_NAME
    )

    remove_multi_column_not_null_constraint(TABLE_NAME, *COLUMNS, constraint_name: NEW_CONSTRAINT_NAME)
  end
end
