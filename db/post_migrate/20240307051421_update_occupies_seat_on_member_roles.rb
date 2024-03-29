# frozen_string_literal: true

class UpdateOccupiesSeatOnMemberRoles < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<~SQL
      UPDATE member_roles SET occupies_seat = TRUE
      WHERE base_access_level > 10 OR (
        base_access_level = 10 AND (
          admin_cicd_variables = true OR
          admin_group_member = true OR
          admin_merge_request = true OR
          admin_terraform_state = true OR
          admin_vulnerability = true OR
          archive_project = true OR
          manage_group_access_tokens = true OR
          manage_project_access_tokens = true OR
          read_dependency = true OR
          read_vulnerability = true OR
          remove_group = true OR
          remove_project = true
        )
      )
    SQL

    execute(sql)
  end

  def down
    sql = <<~SQL
      UPDATE member_roles SET occupies_seat = FALSE
    SQL

    execute(sql)
  end
end
