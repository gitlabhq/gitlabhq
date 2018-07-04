class AddGeoNodesVerificationMaxCapacity < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_nodes, :verification_max_capacity, :integer, default: 100, null: false
  end
end
