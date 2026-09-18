# frozen_string_literal: true

class QueueBackfillOccurrenceIdToSbomOccurrencesVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillOccurrenceIdToSbomOccurrencesVulnerabilities"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_occurrences_vulnerabilities,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_occurrences_vulnerabilities, :id, [])
  end
end
