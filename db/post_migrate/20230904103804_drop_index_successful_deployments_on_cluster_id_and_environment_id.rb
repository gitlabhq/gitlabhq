# frozen_string_literal: true

class DropIndexSuccessfulDeploymentsOnClusterIdAndEnvironmentId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_successful_deployments_on_cluster_id_and_environment_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX index_successful_deployments_on_cluster_id_and_environment_id ON deployments
    #   USING btree (cluster_id, environment_id) WHERE (status = 2);
    add_concurrent_index :deployments, %i[cluster_id environment_id], name: INDEX_NAME, where: 'status = 2'
  end
end
