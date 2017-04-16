class AddLatestToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_builds, :latest, :boolean, default: true)
  end

  def down
    remove_column(:ci_builds, :latest)
  end
end
