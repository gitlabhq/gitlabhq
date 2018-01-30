# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEEForeignKeysPointingToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  TABLES = [
    :push_rules,
    :index_statuses,
    :remote_mirrors,
    :path_locks
  ]

  def up
    # These foreign keys lack an ON DELETE clause.
    remove_foreign_key_without_error(:path_locks, column: :project_id)
    remove_foreign_key_without_error(:remote_mirrors, column: :project_id)

    TABLES.each do |table|
      quoted_table = connection.quote_table_name(table)

      execute <<-EOF
      DELETE FROM #{quoted_table}
      WHERE NOT EXISTS (
        SELECT true
        FROM projects
        WHERE projects.id = #{quoted_table}.project_id
      )
      AND project_id IS NOT NULL
      EOF

      add_concurrent_foreign_key(table, :projects, column: :project_id)
    end
  end

  def down
    # We'll leave the path_locks / remote_mirrors foreign keys in place since
    # there's no particular reason to remove the ON DELETE clause here.
    [:push_rules, :index_statuses].each do |table|
      remove_foreign_key_without_error(table, column: :project_id)
    end
  end

  def remove_foreign_key_without_error(*args)
    remove_foreign_key(*args)
  rescue ArgumentError
  end
end
