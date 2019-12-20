# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ProjectNameLowerIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_projects_on_lower_name'

  disable_ddl_transaction!

  def up
    disable_statement_timeout do
      execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON projects (LOWER(name))"
    end
  end

  def down
    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
    end
  end
end
