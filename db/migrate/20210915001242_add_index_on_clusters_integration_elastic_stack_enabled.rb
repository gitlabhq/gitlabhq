# frozen_string_literal: true

class AddIndexOnClustersIntegrationElasticStackEnabled < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_clusters_integration_elasticstack_enabled'

  def up
    add_concurrent_index(:clusters_integration_elasticstack, [:enabled, :created_at, :cluster_id], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:clusters_integration_elasticstack, INDEX_NAME)
  end
end
