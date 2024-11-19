# frozen_string_literal: true

class FinalizeBackfillShardingKeyIdOnCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillShardingKeyIdOnCiRunners',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: []
    )
  end

  def down; end
end
