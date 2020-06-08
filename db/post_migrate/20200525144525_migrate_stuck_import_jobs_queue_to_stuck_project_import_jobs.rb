# frozen_string_literal: true

class MigrateStuckImportJobsQueueToStuckProjectImportJobs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'cronjob:stuck_import_jobs', to: 'cronjob:import_stuck_project_import_jobs'
  end

  def down
    sidekiq_queue_migrate 'cronjob:import_stuck_project_import_jobs', to: 'cronjob:stuck_import_jobs'
  end
end
