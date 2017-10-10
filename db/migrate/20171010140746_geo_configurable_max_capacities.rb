class GeoConfigurableMaxCapacities < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :geo_nodes, :files_max_capacity, :integer, allow_null: false, default: 10
    add_column_with_default :geo_nodes, :repos_max_capacity, :integer, allow_null: false, default: 25
  end

  def down
    remove_column :geo_nodes, :files_max_capacity, :integer
    remove_column :geo_nodes, :repos_max_capacity, :integer
  end
end
