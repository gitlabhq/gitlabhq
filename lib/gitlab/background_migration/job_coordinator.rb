# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class responsible for executing background migrations based on the given database.
    #
    # Chooses the correct worker class when selecting jobs from the queue based on the
    # convention of how the queues and worker classes are setup for each database.
    #
    # Also provides a database connection to the correct tracking database.
    class JobCoordinator # rubocop:disable Metrics/ClassLength
      class << self
        def for_tracking_database(tracking_database)
          worker_class = worker_for_tracking_database[tracking_database]

          if worker_class.nil?
            raise ArgumentError, "The '#{tracking_database}' must be one of #{worker_for_tracking_database.keys.to_a}"
          end

          new(worker_class)
        end

        private

        def worker_classes
          @worker_classes ||= [
            ::BackgroundMigrationWorker,
            ::BackgroundMigration::CiDatabaseWorker
          ].freeze
        end

        def worker_for_tracking_database
          @worker_for_tracking_database ||= worker_classes
            .select { |worker_class| Gitlab::Database.has_config?(worker_class.tracking_database) }
            .index_by(&:tracking_database)
            .with_indifferent_access
            .freeze
        end
      end

      attr_reader :worker_class

      delegate :minimum_interval, :perform_in, to: :worker_class

      def queue
        @queue ||= worker_class.sidekiq_options['queue']
      end

      def sidekiq_redis_pool
        @sidekiq_redis_pool ||=
          Gitlab::SidekiqSharding::Router.get_shard_instance(worker_class.sidekiq_options['store']).last
      end

      def with_shared_connection(&block)
        Gitlab::Database::SharedModel.using_connection(connection, &block)
      end

      def pending_jobs(include_dead_jobs: false)
        Enumerator.new do |y|
          Sidekiq::Client.via(sidekiq_redis_pool) do
            queues = [
              Sidekiq::ScheduledSet.new,
              Sidekiq::Queue.new(self.queue)
            ]

            if include_dead_jobs
              queues << Sidekiq::RetrySet.new
              queues << Sidekiq::DeadSet.new
            end

            queues.each do |queue|
              queue.each do |job|
                y << job if job.klass == worker_class.name
              end
            end
          end
        end
      end

      def steal(steal_class, retry_dead_jobs: false)
        with_shared_connection do
          Sidekiq::Client.via(sidekiq_redis_pool) do
            pending_jobs(include_dead_jobs: retry_dead_jobs).each do |job|
              migration_class, migration_args = job.args

              next unless migration_class == steal_class
              next if block_given? && !(yield job)

              begin
                perform(migration_class, migration_args) if job.delete
              rescue Exception # rubocop:disable Lint/RescueException
                worker_class # enqueue this migration again
                  .perform_async(migration_class, migration_args)

                raise
              end
            end
          end
        end
      end

      def perform(class_name, arguments)
        with_shared_connection do
          migration_instance_for(class_name).perform(*arguments)
        end
      end

      def remaining
        enqueued = Sidekiq::Queue.new(self.queue)
        Sidekiq::Client.via(sidekiq_redis_pool) do
          scheduled = Sidekiq::ScheduledSet.new

          [enqueued, scheduled].sum do |set|
            set.count do |job|
              job.klass == worker_class.name
            end
          end
        end
      end

      def exists?(migration_class, additional_queues = [])
        enqueued = Sidekiq::Queue.new(self.queue)
        Sidekiq::Client.via(sidekiq_redis_pool) do
          scheduled = Sidekiq::ScheduledSet.new

          enqueued_job?([enqueued, scheduled], migration_class)
        end
      end

      def dead_jobs?(migration_class)
        Sidekiq::Client.via(sidekiq_redis_pool) do
          dead_set = Sidekiq::DeadSet.new

          enqueued_job?([dead_set], migration_class)
        end
      end

      def retrying_jobs?(migration_class)
        Sidekiq::Client.via(sidekiq_redis_pool) do
          retry_set = Sidekiq::RetrySet.new

          enqueued_job?([retry_set], migration_class)
        end
      end

      def migration_instance_for(class_name)
        migration_class = migration_class_for(class_name)

        if migration_class < Gitlab::BackgroundMigration::BaseJob
          migration_class.new(connection: connection)
        else
          migration_class.new
        end
      end

      def migration_class_for(class_name)
        Gitlab::BackgroundMigration.const_get(class_name, false)
      end

      def enqueued_job?(queues, migration_class)
        queues.any? do |queue|
          queue.any? do |job|
            job.klass == worker_class.name && job.args.first == migration_class
          end
        end
      end

      private

      def initialize(worker_class)
        @worker_class = worker_class
      end

      def connection
        @connection ||= Gitlab::Database
          .database_base_models
          .fetch(worker_class.tracking_database)
          .connection
      end
    end
  end
end
