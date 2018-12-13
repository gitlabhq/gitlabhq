# frozen_string_literal: true

class BackfillStoreProjectFullPathInRepo < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME       = false
  BATCH_SIZE     = 1_000
  DELAY_INTERVAL = 5.minutes
  UP_MIGRATION   = 'BackfillProjectFullpathInRepoConfig::Up'
  DOWN_MIGRATION = 'BackfillProjectFullpathInRepoConfig::Down'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project, UP_MIGRATION, DELAY_INTERVAL)
  end

  def down
    queue_background_migration_jobs_by_range_at_intervals(Project, DOWN_MIGRATION, DELAY_INTERVAL)
  end
end
