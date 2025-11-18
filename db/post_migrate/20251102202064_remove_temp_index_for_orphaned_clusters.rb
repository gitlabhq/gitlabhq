# frozen_string_literal: true

class RemoveTempIndexForOrphanedClusters < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  INDEX_NAME = 'tmp_index_clusters_on_id_where_project_and_group_null'

  def up
    remove_concurrent_index_by_name :clusters, name: INDEX_NAME
  end

  def down
    add_concurrent_index :clusters, :id, where: 'project_id IS NULL AND group_id IS NULL',
      name: INDEX_NAME
  end
end
