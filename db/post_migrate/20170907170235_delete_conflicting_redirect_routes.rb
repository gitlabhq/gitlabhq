# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DeleteConflictingRedirectRoutes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1000 # Number of rows to process per job
  JOB_BUFFER_SIZE = 1000 # Number of jobs to bulk queue at a time
  MIGRATION = 'DeleteConflictingRedirectRoutes'.freeze

  disable_ddl_transaction!

  class Route < ActiveRecord::Base
    include EachBatch

    self.table_name = 'routes'
  end

  def up
    jobs = []

    say opening_message

    queue_background_migration_jobs(Route, MIGRATION)
  end

  def down
    # nothing
  end

  def opening_message
    <<~MSG
      Clean up redirect routes that conflict with regular routes.
         See initial bug fix:
         https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/13357
    MSG
  end

  def queue_background_migration_jobs(model_class, job_class_name, batch_size = BATCH_SIZE)
    jobs = []

    model_class.each_batch(of: batch_size) do |relation|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

      # Note: This conditional will only be true if JOB_BUFFER_SIZE * batch_size < (total number of rows)
      if jobs.length >= JOB_BUFFER_SIZE
        # We push multiple jobs at a time to reduce the time spent in
        # Sidekiq/Redis operations. We're using this buffer based approach so we
        # don't need to run additional queries for every range.
        bulk_queue_jobs(jobs)
        jobs.clear
      end

      jobs << [job_class_name, [start_id, end_id]]
    end

    bulk_queue_jobs(jobs) unless jobs.empty?
  end

  def bulk_queue_jobs(jobs)
    say "Queuing #{jobs.size} BackgroundMigrationWorker jobs..."

    BackgroundMigrationWorker.perform_bulk(jobs)
  end
end
