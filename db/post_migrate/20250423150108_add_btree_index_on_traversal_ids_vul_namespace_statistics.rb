# frozen_string_literal: true

class AddBtreeIndexOnTraversalIdsVulNamespaceStatistics < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  INDEX_NAME = 'index_vuln_namespace_statistics_btree_traversal_ids'

  def up
    add_concurrent_index :vulnerability_namespace_statistics, :traversal_ids, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_namespace_statistics, name: INDEX_NAME
  end
end
