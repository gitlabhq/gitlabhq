# frozen_string_literal: true

class FinalizeDeleteOrphanedCiRunnerMachineRecordsOnSelfManaged < Gitlab::Database::Migration[2.3]
  milestone '18.3'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    return if Gitlab.com_except_jh?

    ensure_batched_background_migration_is_finished(
      job_class_name: 'DeleteOrphanedCiRunnerMachineRecordsOnSelfManaged',
      table_name: :ci_runner_machines,
      column_name: :runner_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
