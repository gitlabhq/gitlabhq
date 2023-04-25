# frozen_string_literal: true

class MarkRecalculateFindingSignaturesAsCompleted < Gitlab::Database::Migration[1.0]
  MIGRATION = 'RecalculateVulnerabilitiesOccurrencesUuid'

  def up
    # Only run migration for Gitlab.com
    return unless ::Gitlab.com?

    # In previous migration marking jobs as successful was missed
    Gitlab::Database::BackgroundMigrationJob
      .for_migration_class(MIGRATION)
      .pending
      .update_all(status: :succeeded)
  end

  def down
    # no-op
  end
end
