# frozen_string_literal: true

class BackfillProjectRepositoriesForLegacyStorageProjects < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME       = false
  BATCH_SIZE     = 1_000
  DELAY_INTERVAL = 5.minutes
  MIGRATION      = 'BackfillLegacyProjectRepositories'

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project, MIGRATION, DELAY_INTERVAL)
  end

  def down
    # no-op: since there could have been existing rows before the migration do not remove anything
  end
end
