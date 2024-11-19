# frozen_string_literal: true

class IndexVulnNamespaceHistoricalStatisticsOnNamespaceIdAndId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_vuln_namespace_hist_statistics_for_traversal_ids_update'

  disable_ddl_transaction!
  milestone '17.6'

  def up
    add_concurrent_index :vulnerability_namespace_historical_statistics, %i[namespace_id id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_namespace_historical_statistics, INDEX_NAME
  end
end
