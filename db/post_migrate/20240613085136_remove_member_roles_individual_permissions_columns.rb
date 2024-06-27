# frozen_string_literal: true

class RemoveMemberRolesIndividualPermissionsColumns < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  PERMISSION_COLUMNS = %i[
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
  ]

  def change
    remove_columns :member_roles, *PERMISSION_COLUMNS, type: :boolean, null: false, default: false
  end
end
