# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleEventMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BUFFER_SIZE = 1000

  disable_ddl_transaction!

  class Event < ActiveRecord::Base
    include EachBatch

    self.table_name = 'events'
  end

  def up
    jobs = []

    Event.each_batch(of: 1000) do |relation|
      min, max = relation.pluck('MIN(id), MAX(id)').first

      if jobs.length == BUFFER_SIZE
        # We push multiple jobs at a time to reduce the time spent in
        # Sidekiq/Redis operations. We're using this buffer based approach so we
        # don't need to run additional queries for every range.
        BackgroundMigrationWorker.bulk_perform_async(jobs)
        jobs.clear
      end

      jobs << ['MigrateEventsToPushEventPayloads', [min, max]]
    end

    BackgroundMigrationWorker.bulk_perform_async(jobs) unless jobs.empty?
  end

  def down
  end
end
