class AddEnabledToGeoNodes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :geo_nodes, :enabled, :boolean, default: true
  end

  def down
    remove_column :geo_nodes, :enabled
  end
end
