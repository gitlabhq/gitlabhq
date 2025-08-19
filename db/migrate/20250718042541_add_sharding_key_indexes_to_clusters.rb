# frozen_string_literal: true

class AddShardingKeyIndexesToClusters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_index :clusters, :project_id, name: 'index_clusters_on_project_id'
    add_concurrent_index :clusters, :group_id, name: 'index_clusters_on_group_id'
    add_concurrent_index :clusters, :organization_id, name: 'index_clusters_on_organization_id'
  end

  def down
    remove_concurrent_index :clusters, :project_id, name: 'index_clusters_on_project_id'
    remove_concurrent_index :clusters, :group_id, name: 'index_clusters_on_group_id'
    remove_concurrent_index :clusters, :organization_id, name: 'index_clusters_on_organization_id'
  end
end
