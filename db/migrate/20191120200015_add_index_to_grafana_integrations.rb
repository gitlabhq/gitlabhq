class AddIndexToGrafanaIntegrations < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :grafana_integrations, :enabled, where: 'enabled IS TRUE'
  end

  def down
    remove_concurrent_index :grafana_integrations, :enabled
  end
end
