# frozen_string_literal: true

class RemoveIndexClustersKubernetesNamespacesOnClusterId < Gitlab::Database::Migration[1.0]
  INDEX = 'index_clusters_kubernetes_namespaces_on_cluster_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :clusters_kubernetes_namespaces, INDEX
  end

  def down
    add_concurrent_index :clusters_kubernetes_namespaces, :cluster_id, name: INDEX
  end
end
