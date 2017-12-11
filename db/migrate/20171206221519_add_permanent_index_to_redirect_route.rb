# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPermanentIndexToRedirectRoute < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:redirect_routes, :permanent)
  end

  def down
    remove_concurrent_index(:redirect_routes, :permanent) if index_exists?(:redirect_routes, :permanent)
  end
end
