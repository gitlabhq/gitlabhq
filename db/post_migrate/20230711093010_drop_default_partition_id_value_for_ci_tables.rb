# frozen_string_literal: true

class DropDefaultPartitionIdValueForCiTables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLES = {
    ci_build_needs: [:partition_id],
    ci_build_pending_states: [:partition_id],
    ci_build_report_results: [:partition_id],
    ci_build_trace_chunks: [:partition_id],
    ci_builds_runner_session: [:partition_id],
    ci_job_variables: [:partition_id],
    ci_pending_builds: [:partition_id],
    ci_pipelines: [:partition_id],
    ci_running_builds: [:partition_id],
    ci_sources_pipelines: [:partition_id, :source_partition_id],
    ci_unit_test_failures: [:partition_id]
  }

  def up
    TABLES.each do |table_name, columns|
      with_lock_retries do
        columns.each do |column_name| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
          change_column_default(table_name, column_name, from: 100, to: nil)
        end
      end
    end
  end

  def down
    TABLES.each do |table_name, columns|
      with_lock_retries do
        columns.each do |column_name| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
          change_column_default(table_name, column_name, from: nil, to: 100)
        end
      end
    end
  end
end
