# frozen_string_literal: true

class FinalizeBackfillCiRunnersPartitionedTable < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiRunnersPartitionedTable',
      table_name: :ci_runners,
      column_name: :id,
      job_arguments: ['ci_runners_e59bb2812d'],
      finalize: true
    )
  end

  def down; end
end
