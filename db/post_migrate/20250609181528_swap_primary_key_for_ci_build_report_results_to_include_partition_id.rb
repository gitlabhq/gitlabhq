# frozen_string_literal: true

class SwapPrimaryKeyForCiBuildReportResultsToIncludePartitionId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = :ci_build_report_results

  PRIMARY_KEY_NAME = :ci_build_report_results_pkey
  OLD_INDEX_NAME = :index_ci_build_report_results_on_build_id
  OLD_COLUMN = :build_id

  NEW_INDEX_NAME = :index_ci_build_report_results_on_build_id_partition_id
  NEW_COLUMNS = [:build_id, :partition_id]

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY_NAME, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, OLD_COLUMN, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, NEW_COLUMNS, unique: true, name: NEW_INDEX_NAME)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY_NAME, OLD_INDEX_NAME)
  end
end
