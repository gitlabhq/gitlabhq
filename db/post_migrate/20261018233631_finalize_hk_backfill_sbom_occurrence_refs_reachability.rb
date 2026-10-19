# frozen_string_literal: true

class FinalizeHkBackfillSbomOccurrenceRefsReachability < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSbomOccurrenceRefsReachability',
      table_name: :sbom_occurrence_refs,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
