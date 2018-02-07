class ChangeGeoNodeStatusColumnSize < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    change_column :geo_node_statuses, :replication_slots_max_retained_wal_bytes, :integer, limit: 8
  end

  def down
    change_column :geo_node_statuses, :replication_slots_max_retained_wal_bytes, :integer, limit: 4
  end
end
