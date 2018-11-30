# frozen_string_literal: true

class BackfillHashedProjectRepositories < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE     = 1_000
  DELAY_INTERVAL = 1.minutes
  MIGRATION      = 'BackfillHashedProjectRepositories'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, DELAY_INTERVAL)
  end

  def down
    # Since there could have been existing rows before the migration
    # do not remove anything
  end
end
