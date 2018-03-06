# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPathIndexToRedirectRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  disable_ddl_transaction!

  INDEX_NAME = 'index_redirect_routes_on_path_unique_text_pattern_ops'

  # Indexing on LOWER(path) varchar_pattern_ops speeds up the LIKE query in
  # RedirectRoute.matching_path_and_descendants
  #
  # This same index is also added in the `ReworkRedirectRoutesIndexes` so this
  # is a no-op in most cases. But this migration is also called from the
  # `setup_postgresql.rake` task when setting up a new database, in which case
  # we want to create the index.
  def up
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout

    if_not_exists = Gitlab::Database.version.to_f >= 9.5 ? "IF NOT EXISTS" : ""

    # Unique index on lower(path) across both types of redirect_routes:
    execute("CREATE UNIQUE INDEX CONCURRENTLY #{if_not_exists} #{INDEX_NAME} ON redirect_routes (lower(path) varchar_pattern_ops);")
  end

  def down
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout

    execute("DROP INDEX IF EXISTS #{INDEX_NAME};")
  end
end
