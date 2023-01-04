# frozen_string_literal: true

class BumpDefaultPartitionIdValueForCiTables < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLES = {
    ci_build_needs: [:partition_id],
    ci_build_pending_states: [:partition_id],
    ci_build_report_results: [:partition_id],
    ci_build_trace_chunks: [:partition_id],
    ci_build_trace_metadata: [:partition_id],
    ci_builds: [:partition_id],
    ci_builds_runner_session: [:partition_id],
    ci_job_artifacts: [:partition_id],
    ci_job_variables: [:partition_id],
    ci_pending_builds: [:partition_id],
    ci_pipeline_variables: [:partition_id],
    ci_pipelines: [:partition_id],
    ci_running_builds: [:partition_id],
    ci_sources_pipelines: [:partition_id, :source_partition_id],
    ci_stages: [:partition_id],
    ci_unit_test_failures: [:partition_id],
    p_ci_builds_metadata: [:partition_id]
  }

  def up
    change_partitions_default_value(from: 100, to: 101)
  end

  def down
    change_partitions_default_value(from: 101, to: 100)
  end

  private

  def change_partitions_default_value(from:, to:)
    return unless Gitlab.com?

    TABLES.each do |table_name, columns|
      next if columns.all? { |column_name| default_value_for(table_name, column_name) == to }

      with_lock_retries do
        columns.each do |column_name| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
          change_column_default(table_name, column_name, from: from, to: to)
        end
      end
    end
  end

  def default_value_for(table_name, column_name)
    connection
      .columns(table_name)
      .find { |column| column.name == column_name.to_s }
      .default&.to_i
  end
end
