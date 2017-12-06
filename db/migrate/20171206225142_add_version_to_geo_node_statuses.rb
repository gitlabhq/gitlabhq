class AddVersionToGeoNodeStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :version, :string
  end
end
