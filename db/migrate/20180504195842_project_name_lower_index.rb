# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ProjectNameLowerIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_lower_name'

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout do
      execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON projects (LOWER(name))"
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout do
      if supports_drop_index_concurrently?
        execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
      else
        execute "DROP INDEX IF EXISTS #{INDEX_NAME}"
      end
    end
  end
end
