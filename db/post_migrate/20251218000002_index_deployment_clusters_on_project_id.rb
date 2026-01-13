# frozen_string_literal: true

class IndexDeploymentClustersOnProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.8'
  disable_ddl_transaction!

  INDEX_NAME = 'index_deployment_clusters_on_project_id'

  def up
    add_concurrent_index :deployment_clusters, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :deployment_clusters, INDEX_NAME
  end
end
