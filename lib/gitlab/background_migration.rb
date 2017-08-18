module Gitlab
  module BackgroundMigration
    def self.queue
      @queue ||= BackgroundMigrationWorker.sidekiq_options['queue']
    end

    # Begins stealing jobs from the background migrations queue, blocking the
    # caller until all jobs have been completed.
    #
    # When a migration raises a StandardError is is going to be retries up to
    # three times, for example, to recover from a deadlock.
    #
    # When Exception is being raised, it enqueues the migration again, and
    # re-raises the exception.
    #
    # steal_class - The name of the class for which to steal jobs.
    def self.steal(steal_class)
      enqueued = Sidekiq::Queue.new(self.queue)
      scheduled = Sidekiq::ScheduledSet.new

      [scheduled, enqueued].each do |queue|
        queue.each do |job|
          migration_class, migration_args = job.args

          next unless job.queue == self.queue
          next unless migration_class == steal_class

          begin
            perform(migration_class, migration_args) if job.delete
          rescue Exception # rubocop:disable Lint/RescueException
            BackgroundMigrationWorker # enqueue this migration again
              .perform_async(migration_class, migration_args)

            raise
          end
        end
      end
    end

    ##
    # Performs a background migration.
    #
    # class_name - The name of the background migration class as defined in the
    #              Gitlab::BackgroundMigration namespace.
    #
    # arguments - The arguments to pass to the background migration's "perform"
    #             method.
    def self.perform(class_name, arguments)
      const_get(class_name).new.perform(*arguments)
    end
  end
end
