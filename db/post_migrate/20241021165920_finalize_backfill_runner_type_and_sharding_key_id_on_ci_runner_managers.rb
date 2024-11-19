# frozen_string_literal: true

class FinalizeBackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '17.6'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers',
      table_name: :ci_runner_machines,
      column_name: :id,
      job_arguments: []
    )
  end

  def down; end
end
