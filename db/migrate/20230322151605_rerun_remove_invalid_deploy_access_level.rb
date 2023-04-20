# frozen_string_literal: true

class RerunRemoveInvalidDeployAccessLevel < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  # clean up any rows with invalid access_level entries
  def up
    update_column_in_batches(:protected_environment_deploy_access_levels, :access_level, nil) do |table, query|
      query.where(
        table.grouping(table[:user_id].not_eq(nil).or(table[:group_id].not_eq(nil)))
             .and(table[:access_level].not_eq(nil)))
    end

    update_column_in_batches(:protected_environment_deploy_access_levels, :group_id, nil) do |table, query|
      query.where(table[:user_id].not_eq(nil).and(table[:group_id].not_eq(nil)))
    end
  end

  def down
    # no-op

    # we are setting access_level to NULL if group_id or user_id are present
  end
end
