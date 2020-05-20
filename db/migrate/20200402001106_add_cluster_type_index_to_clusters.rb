# frozen_string_literal: true

class AddClusterTypeIndexToClusters < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false
  INDEX_NAME = 'index_clusters_on_enabled_cluster_type_id_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :clusters, [:enabled, :cluster_type, :id, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :clusters, INDEX_NAME
  end
end
