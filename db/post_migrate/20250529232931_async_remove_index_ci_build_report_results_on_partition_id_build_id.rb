# frozen_string_literal: true

class AsyncRemoveIndexCiBuildReportResultsOnPartitionIdBuildId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  TABLE_NAME = :ci_build_report_results
  INDEX_NAME = :index_ci_build_report_results_on_partition_id_build_id
  COLUMNS = [:partition_id, :build_id]

  def up
    prepare_async_index_removal TABLE_NAME, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end
