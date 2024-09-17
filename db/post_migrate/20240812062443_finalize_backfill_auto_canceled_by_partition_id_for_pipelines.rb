# frozen_string_literal: true

class FinalizeBackfillAutoCanceledByPartitionIdForPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'QueueBackfillAutocancelPartitionIdOnCiPipelines'
  TABLE_NAME = :ci_pipelines
  COLUMN_NAME = :id

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: TABLE_NAME,
      column_name: COLUMN_NAME,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
