# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UsersNameLowerIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_on_users_name_lower'

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    # On GitLab.com this produces an index with a size of roughly 60 MB.
    execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON users (LOWER(name))"
  end

  def down
    return unless Gitlab::Database.postgresql?

    if supports_drop_index_concurrently?
      execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
    else
      execute "DROP INDEX IF EXISTS #{INDEX_NAME}"
    end
  end
end
