# frozen_string_literal: true

class DropIndexVulnNamespaceHistoricalStatisticsOnNamespaceId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_vuln_namespace_historical_statistics_on_namespace_id'

  disable_ddl_transaction!
  milestone '17.6'

  def up
    remove_concurrent_index_by_name :vulnerability_namespace_historical_statistics, INDEX_NAME
  end

  def down
    add_concurrent_index :vulnerability_namespace_historical_statistics, :namespace_id, name: INDEX_NAME
  end
end
