# frozen_string_literal: true

class FinalizeBackfillFindingInitialPipelineId < Gitlab::Database::Migration[2.2]
  MIGRATION = 'BackfillFindingInitialPipelineId'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.3'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :vulnerability_occurrences,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
