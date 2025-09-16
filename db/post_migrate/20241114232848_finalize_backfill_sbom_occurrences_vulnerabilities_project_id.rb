# frozen_string_literal: true

class FinalizeBackfillSbomOccurrencesVulnerabilitiesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSbomOccurrencesVulnerabilitiesProjectId',
      table_name: :sbom_occurrences_vulnerabilities,
      column_name: :id,
      job_arguments: [:project_id, :sbom_occurrences, :project_id, :sbom_occurrence_id],
      finalize: true
    )
  end

  def down; end
end
