# frozen_string_literal: true

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
    def self.steal(steal_class, retry_dead_jobs: false)
      queues = [
        Sidekiq::ScheduledSet.new,
        Sidekiq::Queue.new(self.queue)
      ]

      if retry_dead_jobs
        queues << Sidekiq::RetrySet.new
        queues << Sidekiq::DeadSet.new
      end

      queues.each do |queue|
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
      migration_class_for(class_name).new.perform(*arguments)
    end

    def self.exists?(migration_class, additional_queues = [])
      enqueued = Sidekiq::Queue.new(self.queue)
      scheduled = Sidekiq::ScheduledSet.new

      enqueued_job?([enqueued, scheduled], migration_class)
    end

    def self.dead_jobs?(migration_class)
      dead_set = Sidekiq::DeadSet.new

      enqueued_job?([dead_set], migration_class)
    end

    def self.retrying_jobs?(migration_class)
      retry_set = Sidekiq::RetrySet.new

      enqueued_job?([retry_set], migration_class)
    end

    def self.migration_class_for(class_name)
      # We don't pass class name with Gitlab::BackgroundMigration:: prefix anymore
      # but some jobs could be already spawned so we need to have some backward compatibility period.
      # Can be removed since 13.x
      full_class_name_prefix_regexp = /\A(::)?Gitlab::BackgroundMigration::/

      if class_name.match(full_class_name_prefix_regexp)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
          StandardError.new("Full class name is used"),
          class_name: class_name
        )

        class_name = class_name.sub(full_class_name_prefix_regexp, '')
      end

      const_get(class_name, false)
    end

    def self.enqueued_job?(queues, migration_class)
      queues.each do |queue|
        queue.each do |job|
          return true if job.queue == self.queue && job.args.first == migration_class
        end
      end

      false
    end
  end
end
