# frozen_string_literal: true

class FinalizeFixBadShardingKeyIdOnProjectCiRunners < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  milestone '18.0'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixBadShardingKeyIdOnProjectCiRunners',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
