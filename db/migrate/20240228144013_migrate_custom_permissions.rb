# frozen_string_literal: true

class MigrateCustomPermissions < Gitlab::Database::Migration[2.2]
  milestone '16.11'
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  PERMISSION_COLUMNS = %w[
    admin_cicd_variables
    admin_group_member
    admin_merge_request
    admin_terraform_state
    admin_vulnerability
    archive_project
    manage_group_access_tokens
    manage_project_access_tokens
    read_code
    read_dependency
    read_vulnerability
    remove_group
    remove_project
  ].join(', ')

  def up
    update_value = Arel.sql("(SELECT to_jsonb ((SELECT perm_cols FROM (SELECT #{PERMISSION_COLUMNS}) perm_cols)))")
    update_column_in_batches(:member_roles, :permissions, update_value)
  end

  def down
    update_column_in_batches(:member_roles, :permissions, '{}')
  end
end
