# frozen_string_literal: true

class FinalizeFindingIdMigrations < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    finalize_finding_id_backfill
    finalize_empty_finding_id_removal
  end

  def down; end

  private

  def finalize_finding_id_backfill
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillFindingIdInVulnerabilities',
      table_name: :vulnerabilities,
      column_name: 'id',
      job_arguments: []
    )
  end

  def finalize_empty_finding_id_removal
    ensure_batched_background_migration_is_finished(
      job_class_name: 'DropVulnerabilitiesWithoutFindingId',
      table_name: :vulnerabilities,
      column_name: 'id',
      job_arguments: []
    )
  end
end
