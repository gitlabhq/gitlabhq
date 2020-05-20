# frozen_string_literal: true

class AddIndexOnSuccessfulDeploymentAndEnvironmentIdToDeployments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_successful_deployments_on_cluster_id_and_environment_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :deployments, [:cluster_id, :environment_id], where: 'status = 2', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :deployments, [:cluster_id, :environment_id], where: 'status = 2', name: INDEX_NAME
  end
end
