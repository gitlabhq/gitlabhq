# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemovePermanentFromRedirectRoutes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  INDEX_NAME_PERM = "index_redirect_routes_on_path_text_pattern_ops_where_permanent"
  INDEX_NAME_TEMP = "index_redirect_routes_on_path_text_pattern_ops_where_temporary"

  def up
    # These indexes were created on Postgres only in:
    # ReworkRedirectRoutesIndexes:
    # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/16211
    disable_statement_timeout do
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME_PERM};"
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME_TEMP};"
    end

    remove_column(:redirect_routes, :permanent)
  end

  def down
    add_column(:redirect_routes, :permanent, :boolean)

    disable_statement_timeout do
      execute("CREATE INDEX CONCURRENTLY #{INDEX_NAME_PERM} ON redirect_routes (lower(path) varchar_pattern_ops) where (permanent);")
      execute("CREATE INDEX CONCURRENTLY #{INDEX_NAME_TEMP} ON redirect_routes (lower(path) varchar_pattern_ops) where (not permanent or permanent is null) ;")
    end
  end
end
