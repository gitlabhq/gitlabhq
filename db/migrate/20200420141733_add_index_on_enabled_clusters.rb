# frozen_string_literal: true

class AddIndexOnEnabledClusters < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_enabled_clusters_on_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :clusters, [:id], where: 'enabled = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index :clusters, [:id], where: 'enabled = true', name: INDEX_NAME
  end
end
