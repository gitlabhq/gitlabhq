# frozen_string_literal: true

class QueueBackfillSolutionToVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSolutionToVulnerabilities"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :vulnerabilities,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerabilities, :id, [])
  end
end
