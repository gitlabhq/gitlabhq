# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ReworkRedirectRoutesIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME_UNIQUE = "index_redirect_routes_on_path_unique_text_pattern_ops"

  INDEX_NAME_PERM = "index_redirect_routes_on_path_text_pattern_ops_where_permanent"
  INDEX_NAME_TEMP = "index_redirect_routes_on_path_text_pattern_ops_where_temporary"

  OLD_INDEX_NAME_PATH_TPOPS = "index_redirect_routes_on_path_text_pattern_ops"
  OLD_INDEX_NAME_PATH_LOWER = "index_on_redirect_routes_lower_path"

  def up
    disable_statement_timeout

    # this is a plain btree on a single boolean column. It'll never be
    # selective enough to be valuable. This class is called by
    # setup_postgresql.rake so it needs to be able to handle this
    # index not existing.
    if index_exists?(:redirect_routes, :permanent)
      remove_concurrent_index(:redirect_routes, :permanent)
    end

    # If we're on MySQL then the existing index on path is ok. But on
    # Postgres we need to clean things up:
    return unless Gitlab::Database.postgresql?

    if_not_exists = Gitlab::Database.version.to_f >= 9.5 ? "IF NOT EXISTS" : ""

    # Unique index on lower(path) across both types of redirect_routes:
    execute("CREATE UNIQUE INDEX CONCURRENTLY #{if_not_exists} #{INDEX_NAME_UNIQUE} ON redirect_routes (lower(path) varchar_pattern_ops);")

    # Make two indexes on path -- one for permanent and one for temporary routes:
    execute("CREATE INDEX CONCURRENTLY #{if_not_exists} #{INDEX_NAME_PERM} ON redirect_routes (lower(path) varchar_pattern_ops) where (permanent);")
    execute("CREATE INDEX CONCURRENTLY #{if_not_exists} #{INDEX_NAME_TEMP} ON redirect_routes (lower(path) varchar_pattern_ops) where (not permanent or permanent is null) ;")

    # Remove the old indexes:

    # This one needed to be on lower(path) but wasn't so it's replaced with the two above
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{OLD_INDEX_NAME_PATH_TPOPS};"

    # This one isn't needed because we only ever do = and LIKE on this
    # column so the varchar_pattern_ops index is sufficient
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{OLD_INDEX_NAME_PATH_LOWER};"
  end

  def down
    disable_statement_timeout

    add_concurrent_index(:redirect_routes, :permanent)

    return unless Gitlab::Database.postgresql?

    execute("CREATE INDEX CONCURRENTLY #{OLD_INDEX_NAME_PATH_TPOPS} ON redirect_routes (path varchar_pattern_ops);")
    execute("CREATE INDEX CONCURRENTLY #{OLD_INDEX_NAME_PATH_LOWER} ON redirect_routes (LOWER(path));")

    execute("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME_UNIQUE};")
    execute("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME_PERM};")
    execute("DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME_TEMP};")
  end
end
