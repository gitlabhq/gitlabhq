# frozen_string_literal: true

class AddUpdatedAtIndexToBillableUsageDailyNamespaceAggregates < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.5'
  disable_ddl_transaction!

  TABLE_NAME = :billable_usage_daily_namespace_aggregates
  INDEX_NAME = :index_billable_usage_daily_ns_aggs_on_updated_at

  def up
    add_concurrent_partitioned_index TABLE_NAME, :updated_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name TABLE_NAME, INDEX_NAME
  end
end
