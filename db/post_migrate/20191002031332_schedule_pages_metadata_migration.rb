# frozen_string_literal: true

class SchedulePagesMetadataMigration < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  BATCH_SIZE = 10_000
  MIGRATION = 'MigratePagesMetadata'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include ::EachBatch

    self.table_name = 'projects'
  end

  def up
    say "Scheduling `#{MIGRATION}` jobs"

    # At the time of writing there are ~10_669_292 records to be inserted for GitLab.com,
    # batches of 10_000 with delay interval of 2 minutes gives us an estimate of close to 36 hours.
    queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, 2.minutes, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
