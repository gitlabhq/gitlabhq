# frozen_string_literal: true

class ScheduleTemporaryPartitioningIndexesRemoval < Gitlab::Database::Migration[2.1]
  INDEXES = [
    [:ci_pipelines, :tmp_index_ci_pipelines_on_partition_id_and_id],
    [:ci_stages, :tmp_index_ci_stages_on_partition_id_and_id],
    [:ci_builds, :tmp_index_ci_builds_on_partition_id_and_id],
    [:ci_build_needs, :tmp_index_ci_build_needs_on_partition_id_and_id],
    [:ci_build_report_results, :tmp_index_ci_build_report_results_on_partition_id_and_build_id],
    [:ci_build_trace_metadata, :tmp_index_ci_build_trace_metadata_on_partition_id_and_id],
    [:ci_job_artifacts, :tmp_index_ci_job_artifacts_on_partition_id_and_id],
    [:ci_pipeline_variables, :tmp_index_ci_pipeline_variables_on_partition_id_and_id],
    [:ci_job_variables, :tmp_index_ci_job_variables_on_partition_id_and_id],
    [:ci_sources_pipelines, :tmp_index_ci_sources_pipelines_on_partition_id_and_id],
    [:ci_sources_pipelines, :tmp_index_ci_sources_pipelines_on_source_partition_id_and_id],
    [:ci_running_builds, :tmp_index_ci_running_builds_on_partition_id_and_id],
    [:ci_pending_builds, :tmp_index_ci_pending_builds_on_partition_id_and_id],
    [:ci_builds_runner_session, :tmp_index_ci_builds_runner_session_on_partition_id_and_id]
  ]

  def up
    INDEXES.each do |table_name, index_name|
      prepare_async_index_removal table_name, nil, name: index_name
    end
  end

  def down
    INDEXES.each do |table_name, index_name|
      unprepare_async_index table_name, nil, name: index_name
    end
  end
end
