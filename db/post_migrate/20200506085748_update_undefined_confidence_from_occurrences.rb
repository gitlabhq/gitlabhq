# frozen_string_literal: true

class UpdateUndefinedConfidenceFromOccurrences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'index_vulnerability_occurrences_on_id_and_confidence_eq_zero'
  DOWNTIME = false

  disable_ddl_transaction!
  BATCH_SIZE = 1_000
  INTERVAL = 2.minutes

  # 286_159 records to be updated on GitLab.com
  def up
    # create temporary index for undefined vulnerabilities
    add_concurrent_index(:vulnerability_occurrences, :id, where: 'confidence = 0', name: INDEX_NAME)

    return unless Gitlab.ee?

    migration = Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceConfidenceLevel
    migration_name = migration.to_s.demodulize
    relation = migration::Occurrence.undefined_confidence
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          migration_name,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release
    remove_concurrent_index(:vulnerability_occurrences, :id, where: 'confidence = 0', name: INDEX_NAME)
    # This migration can not be reversed because we can not know which records had undefined confidence
  end
end
