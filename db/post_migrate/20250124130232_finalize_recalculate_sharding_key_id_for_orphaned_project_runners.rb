# frozen_string_literal: true

class FinalizeRecalculateShardingKeyIdForOrphanedProjectRunners < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'RecalculateShardingKeyIdForOrphanedProjectRunners',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
