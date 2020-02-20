# frozen_string_literal: true

class BackfillProjectSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'BackfillProjectSettings'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    say "Scheduling `#{MIGRATION}` jobs"

    queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # NOOP
  end
end
