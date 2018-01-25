class AddGeoReplicationSlotStatus < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :replication_slots_count, :integer
    add_column :geo_node_statuses, :replication_slots_used_count, :integer
    add_column :geo_node_statuses, :replication_slots_max_retained_wal_bytes, :integer
  end
end
