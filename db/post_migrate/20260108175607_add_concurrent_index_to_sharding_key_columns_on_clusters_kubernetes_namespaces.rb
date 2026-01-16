# frozen_string_literal: true

class AddConcurrentIndexToShardingKeyColumnsOnClustersKubernetesNamespaces < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  TABLE_NAME = 'clusters_kubernetes_namespaces'

  ORGANIZATION_INDEX = 'idx_clusters_kubernetes_namespaces_on_organization_id'
  GROUP_INDEX = 'idx_clusters_kubernetes_namespaces_on_group_id'
  PROJECT_INDEX = 'idx_clusters_kubernetes_namespaces_on_sharding_project_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: ORGANIZATION_INDEX
    add_concurrent_index TABLE_NAME, :group_id, name: GROUP_INDEX
    add_concurrent_index TABLE_NAME, :sharding_project_id, name: PROJECT_INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, PROJECT_INDEX
    remove_concurrent_index_by_name TABLE_NAME, GROUP_INDEX
    remove_concurrent_index_by_name TABLE_NAME, ORGANIZATION_INDEX
  end
end
