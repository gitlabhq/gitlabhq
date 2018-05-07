class MigrateImportAttributesDataFromProjectsToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  UP_MIGRATION = 'PopulateImportState'.freeze
  DOWN_MIGRATION = 'RollbackImportStateData'.freeze

  BATCH_SIZE = 1000
  DELAY_INTERVAL = 5.minutes

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
  end

  class ProjectImportState < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_mirror_data'
  end

  def up
    projects = Project.where.not(import_status: :none)

    queue_background_migration_jobs_by_range_at_intervals(projects, UP_MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    import_state = ProjectImportState.where.not(status: :none)

    queue_background_migration_jobs_by_range_at_intervals(import_state, DOWN_MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end
end
