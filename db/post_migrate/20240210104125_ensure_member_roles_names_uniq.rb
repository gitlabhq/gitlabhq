# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class EnsureMemberRolesNamesUniq < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    sql = <<~SQL
      UPDATE member_roles SET name = CONCAT(name, ' (', id, ')')
      WHERE id IN (
        SELECT mr.id FROM member_roles mr
        WHERE EXISTS (SELECT mr_duplicates.id
          FROM member_roles mr_duplicates
          WHERE mr_duplicates.name = mr.name
          AND (
            mr_duplicates.namespace_id = mr.namespace_id
            OR (mr_duplicates.namespace_id IS NULL AND mr.namespace_id IS NULL)
          )
          AND mr_duplicates.id < mr.id))
    SQL

    execute(sql)
  end

  def down; end
end
