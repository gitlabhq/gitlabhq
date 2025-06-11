# frozen_string_literal: true

class ChangeIdxCiBuildReportResultsOnBuildIdPartitionId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = :ci_build_report_results

  OLD_INDEX_NAME = :index_ci_build_report_results_on_partition_id_build_id
  OLD_COLUMNS = [:partition_id, :build_id]

  NEW_INDEX_NAME = :index_ci_build_report_results_on_build_id_partition_id
  NEW_COLUMNS = [:build_id, :partition_id]

  def up
    add_concurrent_index(TABLE_NAME, NEW_COLUMNS, unique: true, name: NEW_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, OLD_COLUMNS, unique: true, name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
