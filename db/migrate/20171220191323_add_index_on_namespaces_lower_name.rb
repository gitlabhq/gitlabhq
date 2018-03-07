class AddIndexOnNamespacesLowerName < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  INDEX_NAME = 'index_on_namespaces_lower_name'

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout

    if Gitlab::Database.version.to_f >= 9.5
      # Allow us to hot-patch the index manually ahead of the migration
      execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS #{INDEX_NAME} ON namespaces (lower(name));"
    else
      execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON namespaces (lower(name));"
    end
  end

  def down
    return unless Gitlab::Database.postgresql?

    disable_statement_timeout

    if Gitlab::Database.version.to_f >= 9.2
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME};"
    else
      execute "DROP INDEX IF EXISTS #{INDEX_NAME};"
    end
  end
end
