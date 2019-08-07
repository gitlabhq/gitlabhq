# frozen_string_literal: true

class IndexClustersKubernetesNamespacesOnEnvironmentId < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_kubernetes_namespaces_on_cluster_project_environment_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :clusters_kubernetes_namespaces, [:cluster_id, :project_id, :environment_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :clusters_kubernetes_namespaces, name: INDEX_NAME
  end
end
