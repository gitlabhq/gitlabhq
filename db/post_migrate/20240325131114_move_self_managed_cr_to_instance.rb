# frozen_string_literal: true

class MoveSelfManagedCrToInstance < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # the migration needs to run only on self-managed
    return if Gitlab.com?

    sql = <<~SQL
      UPDATE member_roles mr SET name = CONCAT(mr.name, ' (', g.name, ' - ', g.id, ')'), namespace_id = NULL
        FROM namespaces g WHERE mr.namespace_id IS NOT NULL AND
        g.id = mr.namespace_id
    SQL

    execute(sql)
  end

  def down; end
end
