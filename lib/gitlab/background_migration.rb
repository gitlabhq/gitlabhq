# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    DEFAULT_TRACKING_DATABASE = Gitlab::Database::MAIN_DATABASE_NAME

    def self.coordinator_for_database(database)
      JobCoordinator.for_tracking_database(database)
    end

    def self.queue(database: DEFAULT_TRACKING_DATABASE)
      coordinator_for_database(database).queue
    end

    # Begins stealing jobs from the background migrations queue, blocking the
    # caller until all jobs have been completed.
    #
    # When a migration raises a StandardError it is going to retry up to
    # three times, for example, to recover from a deadlock.
    #
    # When Exception is being raised, it enqueues the migration again, and
    # re-raises the exception.
    #
    # steal_class - The name of the class for which to steal jobs.
    # retry_dead_jobs - Flag to control whether jobs in Sidekiq::RetrySet or Sidekiq::DeadSet are retried.
    # database - tracking database this migration executes against
    def self.steal(steal_class, retry_dead_jobs: false, database: DEFAULT_TRACKING_DATABASE, &block)
      coordinator_for_database(database).steal(steal_class, retry_dead_jobs: retry_dead_jobs, &block)
    end

    ##
    # Performs a background migration.
    #
    # class_name - The name of the background migration class as defined in the
    #              Gitlab::BackgroundMigration namespace.
    #
    # arguments - The arguments to pass to the background migration's "perform"
    #             method.
    # database - tracking database this migration executes against
    def self.perform(class_name, arguments, database: DEFAULT_TRACKING_DATABASE)
      coordinator_for_database(database).perform(class_name, arguments)
    end

    def self.exists?(migration_class, additional_queues = [], database: DEFAULT_TRACKING_DATABASE)
      coordinator_for_database(database).exists?(migration_class, additional_queues) # rubocop:disable CodeReuse/ActiveRecord
    end

    def self.remaining(database: DEFAULT_TRACKING_DATABASE)
      coordinator_for_database(database).remaining
    end
  end
end
