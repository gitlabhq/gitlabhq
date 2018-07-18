class AddStorageConfigurationDigest < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :storage_configuration_digest, :binary
  end
end
