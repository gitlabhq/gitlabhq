# frozen_string_literal: true

class DropClustersIntegrationElasticstackTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_clusters_integration_elasticstack_enabled'

  def up
    drop_table :clusters_integration_elasticstack
  end

  def down
    create_table :clusters_integration_elasticstack, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :cluster, primary_key: true, type: :bigint, default: nil, index: false
      t.boolean :enabled, null: false, default: false
      t.text :chart_version, limit: 10
    end

    add_concurrent_index(:clusters_integration_elasticstack, [:enabled, :created_at, :cluster_id], name: INDEX_NAME)
  end
end
