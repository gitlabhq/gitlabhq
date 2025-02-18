# frozen_string_literal: true

class FinalizeBackfillCiRunnerMachinesPartitionedTable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiRunnerMachinesPartitionedTable',
      table_name: :ci_runner_machines,
      column_name: :id,
      job_arguments: ['ci_runner_machines_687967fa8a'],
      finalize: true
    )
  end

  def down; end
end
