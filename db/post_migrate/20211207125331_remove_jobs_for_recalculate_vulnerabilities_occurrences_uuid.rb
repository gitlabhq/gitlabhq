# frozen_string_literal: true

class RemoveJobsForRecalculateVulnerabilitiesOccurrencesUuid < Gitlab::Database::Migration[1.0]
  MIGRATION_NAME = 'RecalculateVulnerabilitiesOccurrencesUuid'

  def up
    delete_job_tracking(
      MIGRATION_NAME,
      status: %w[pending succeeded]
    )
  end

  def down
    # no-op
  end
end
