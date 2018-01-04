# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddPermanentToRedirectRoute < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column(:redirect_routes, :permanent, :boolean)
  end

  def down
    remove_column(:redirect_routes, :permanent)
  end
end
