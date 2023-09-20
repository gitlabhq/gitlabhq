# frozen_string_literal: true

class DropIndexDeploymentsOnIdWhereClusterIdPresent < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_deployments_on_id_where_cluster_id_present'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :deployments, name: INDEX_NAME
  end

  def down
    # This is based on the following `CREATE INDEX` command in db/init_structure.sql:
    # CREATE INDEX index_deployments_on_id_where_cluster_id_present ON deployments
    #   USING btree (id) WHERE (cluster_id IS NOT NULL);
    add_concurrent_index :deployments, :id, name: INDEX_NAME, where: 'cluster_id IS NOT NULL'
  end
end
