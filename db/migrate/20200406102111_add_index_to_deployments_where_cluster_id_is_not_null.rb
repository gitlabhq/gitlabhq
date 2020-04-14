# frozen_string_literal: true

class AddIndexToDeploymentsWhereClusterIdIsNotNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, :id, where: 'cluster_id IS NOT NULL', name: 'index_deployments_on_id_where_cluster_id_present'
  end

  def down
    remove_concurrent_index :deployments, :id, where: 'cluster_id IS NOT NULL', name: 'index_deployments_on_id_where_cluster_id_present'
  end
end
