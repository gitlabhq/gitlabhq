# frozen_string_literal: true

class FinalizeRecalculateShardingKeyIdForOrphanedProjectRunnerManagers < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RecalculateShardingKeyIdForOrphanedProjectRunnerManagers',
      table_name: :ci_runner_machines,
      column_name: :runner_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
