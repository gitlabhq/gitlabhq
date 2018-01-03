# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexToRedirectRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:redirect_routes, :path, unique: true)
    add_concurrent_index(:redirect_routes, [:source_type, :source_id])
  end

  def down
    remove_concurrent_index(:redirect_routes, :path) if index_exists?(:redirect_routes, :path)
    remove_concurrent_index(:redirect_routes, [:source_type, :source_id]) if index_exists?(:redirect_routes, [:source_type, :source_id])
  end
end
