# frozen_string_literal: true

class UpdateOccurrenceSeverityColumn < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!
  BATCH_SIZE = 1_000
  INTERVAL = 5.minutes

  # 23_044 records to be updated on GitLab.com,
  def up
    # create temporary index for undefined vulnerabilities
    add_concurrent_index(:vulnerability_occurrences, :id, where: 'severity = 0', name: 'undefined_vulnerabilities')

    return unless Gitlab.ee?

    migration = Gitlab::BackgroundMigration::RemoveUndefinedOccurrenceSeverityLevel
    migration_name = migration.to_s.demodulize
    relation = migration::Occurrence.undefined_severity
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          migration_name,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
    # temporary index is to be dropped in a different migration in an upcoming release
    remove_concurrent_index(:vulnerability_occurrences, :id, where: 'severity = 0', name: 'undefined_vulnerabilities')
    # This migration can not be reversed because we can not know which records had undefined severity
  end
end
