# frozen_string_literal: true

class FinalizeRequeueBackfillPCiRunnerMachineBuildsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'BackfillPCiRunnerMachineBuildsProjectId'
  TABLE_NAME = :p_ci_runner_machine_builds
  BATCH_COLUMN = :build_id
  JOB_ARGS = %i[project_id p_ci_builds project_id build_id partition_id]

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: TABLE_NAME,
      column_name: BATCH_COLUMN,
      job_arguments: JOB_ARGS
    )
  end

  def down
    # no-op
  end
end
