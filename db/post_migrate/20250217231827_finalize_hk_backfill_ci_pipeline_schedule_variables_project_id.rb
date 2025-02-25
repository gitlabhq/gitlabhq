# frozen_string_literal: true

class FinalizeHkBackfillCiPipelineScheduleVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiPipelineScheduleVariablesProjectId',
      table_name: :ci_pipeline_schedule_variables,
      column_name: :id,
      job_arguments: [:project_id, :ci_pipeline_schedules, :project_id, :pipeline_schedule_id],
      finalize: true
    )
  end

  def down; end
end
