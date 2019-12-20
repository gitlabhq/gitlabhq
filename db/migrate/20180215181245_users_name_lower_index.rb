# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UsersNameLowerIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_on_users_name_lower'

  disable_ddl_transaction!

  def up
    # On GitLab.com this produces an index with a size of roughly 60 MB.
    execute "CREATE INDEX CONCURRENTLY #{INDEX_NAME} ON users (LOWER(name))"
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS #{INDEX_NAME}"
  end
end
