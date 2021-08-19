# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module BackgroundMigrationHelpers
        BATCH_SIZE = 1_000 # Number of rows to process per job
        SUB_BATCH_SIZE = 100 # Number of rows to process per sub-batch
        JOB_BUFFER_SIZE = 1_000 # Number of jobs to bulk queue at a time
        BATCH_CLASS_NAME = 'PrimaryKeyBatchingStrategy' # Default batch class for batched migrations
        BATCH_MIN_VALUE = 1 # Default minimum value for batched migrations
        BATCH_MIN_DELAY = 2.minutes.freeze # Minimum delay between batched migrations

        # Bulk queues background migration jobs for an entire table, batched by ID range.
        # "Bulk" meaning many jobs will be pushed at a time for efficiency.
        # If you need a delay interval per job, then use `queue_background_migration_jobs_by_range_at_intervals`.
        #
        # model_class - The table being iterated over
        # job_class_name - The background migration job class as a string
        # batch_size - The maximum number of rows per job
        #
        # Example:
        #
        #     class Route < ActiveRecord::Base
        #       include EachBatch
        #       self.table_name = 'routes'
        #     end
        #
        #     bulk_queue_background_migration_jobs_by_range(Route, 'ProcessRoutes')
        #
        # Where the model_class includes EachBatch, and the background migration exists:
        #
        #     class Gitlab::BackgroundMigration::ProcessRoutes
        #       def perform(start_id, end_id)
        #         # do something
        #       end
        #     end
        def bulk_queue_background_migration_jobs_by_range(model_class, job_class_name, batch_size: BATCH_SIZE)
          raise "#{model_class} does not have an ID to use for batch ranges" unless model_class.column_names.include?('id')

          jobs = []
          table_name = model_class.quoted_table_name

          model_class.each_batch(of: batch_size) do |relation|
            start_id, end_id = relation.pluck("MIN(#{table_name}.id)", "MAX(#{table_name}.id)").first

            if jobs.length >= JOB_BUFFER_SIZE
              # Note: This code path generally only helps with many millions of rows
              # We push multiple jobs at a time to reduce the time spent in
              # Sidekiq/Redis operations. We're using this buffer based approach so we
              # don't need to run additional queries for every range.
              bulk_migrate_async(jobs)
              jobs.clear
            end

            jobs << [job_class_name, [start_id, end_id]]
          end

          bulk_migrate_async(jobs) unless jobs.empty?
        end

        # Queues background migration jobs for an entire table in batches.
        # The default batching column used is the standard primary key `id`.
        # Each job is scheduled with a `delay_interval` in between.
        # If you use a small interval, then some jobs may run at the same time.
        #
        # model_class - The table or relation being iterated over
        # job_class_name - The background migration job class as a string
        # delay_interval - The duration between each job's scheduled time (must respond to `to_f`)
        # batch_size - The maximum number of rows per job
        # other_arguments - Other arguments to send to the job
        # track_jobs - When this flag is set, creates a record in the background_migration_jobs table for each job that
        # is scheduled to be run. These records can be used to trace execution of the background job, but there is no
        # builtin support to manage that automatically at this time. You should only set this flag if you are aware of
        # how it works, and intend to manually cleanup the database records in your background job.
        # primary_column_name - The name of the primary key column if the primary key is not `id`
        #
        # *Returns the final migration delay*
        #
        # Example:
        #
        #     class Route < ActiveRecord::Base
        #       include EachBatch
        #       self.table_name = 'routes'
        #     end
        #
        #     queue_background_migration_jobs_by_range_at_intervals(Route, 'ProcessRoutes', 1.minute)
        #
        # Where the model_class includes EachBatch, and the background migration exists:
        #
        #     class Gitlab::BackgroundMigration::ProcessRoutes
        #       def perform(start_id, end_id)
        #         # do something
        #       end
        #     end
        def queue_background_migration_jobs_by_range_at_intervals(model_class, job_class_name, delay_interval, batch_size: BATCH_SIZE, other_job_arguments: [], initial_delay: 0, track_jobs: false, primary_column_name: :id)
          raise "#{model_class} does not have an ID column of #{primary_column_name} to use for batch ranges" unless model_class.column_names.include?(primary_column_name.to_s)
          raise "#{primary_column_name} is not an integer column" unless model_class.columns_hash[primary_column_name.to_s].type == :integer

          # To not overload the worker too much we enforce a minimum interval both
          # when scheduling and performing jobs.
          if delay_interval < BackgroundMigrationWorker.minimum_interval
            delay_interval = BackgroundMigrationWorker.minimum_interval
          end

          final_delay = 0
          batch_counter = 0

          model_class.each_batch(of: batch_size) do |relation, index|
            max = relation.arel_table[primary_column_name].maximum
            min = relation.arel_table[primary_column_name].minimum

            start_id, end_id = relation.pluck(min, max).first

            # `BackgroundMigrationWorker.bulk_perform_in` schedules all jobs for
            # the same time, which is not helpful in most cases where we wish to
            # spread the work over time.
            final_delay = initial_delay + delay_interval * index
            full_job_arguments = [start_id, end_id] + other_job_arguments

            track_in_database(job_class_name, full_job_arguments) if track_jobs
            migrate_in(final_delay, job_class_name, full_job_arguments)

            batch_counter += 1
          end

          duration = initial_delay + delay_interval * batch_counter
          say <<~SAY
            Scheduled #{batch_counter} #{job_class_name} jobs with a maximum of #{batch_size} records per batch and an interval of #{delay_interval} seconds.

            The migration is expected to take at least #{duration} seconds. Expect all jobs to have completed after #{Time.zone.now + duration}."
          SAY

          final_delay
        end

        # Requeue pending jobs previously queued with #queue_background_migration_jobs_by_range_at_intervals
        #
        # This method is useful to schedule jobs that had previously failed.
        #
        # job_class_name - The background migration job class as a string
        # delay_interval - The duration between each job's scheduled time
        # batch_size - The maximum number of jobs to fetch to memory from the database.
        def requeue_background_migration_jobs_by_range_at_intervals(job_class_name, delay_interval, batch_size: BATCH_SIZE, initial_delay: 0)
          # To not overload the worker too much we enforce a minimum interval both
          # when scheduling and performing jobs.
          delay_interval = [delay_interval, BackgroundMigrationWorker.minimum_interval].max

          final_delay = 0
          job_counter = 0

          jobs = Gitlab::Database::BackgroundMigrationJob.pending.where(class_name: job_class_name)
          jobs.each_batch(of: batch_size) do |job_batch|
            job_batch.each do |job|
              final_delay = initial_delay + delay_interval * job_counter

              migrate_in(final_delay, job_class_name, job.arguments)

              job_counter += 1
            end
          end

          duration = initial_delay + delay_interval * job_counter
          say <<~SAY
            Scheduled #{job_counter} #{job_class_name} jobs with an interval of #{delay_interval} seconds.

            The migration is expected to take at least #{duration} seconds. Expect all jobs to have completed after #{Time.zone.now + duration}."
          SAY

          duration
        end

        # Creates a batched background migration for the given table. A batched migration runs one job
        # at a time, computing the bounds of the next batch based on the current migration settings and the previous
        # batch bounds. Each job's execution status is tracked in the database as the migration runs. The given job
        # class must be present in the Gitlab::BackgroundMigration module, and the batch class (if specified) must be
        # present in the Gitlab::BackgroundMigration::BatchingStrategies module.
        #
        # If migration with same job_class_name, table_name, column_name, and job_aruments already exists, this helper
        # will log an warning and not create a new one.
        #
        # job_class_name - The background migration job class as a string
        # batch_table_name - The name of the table the migration will batch over
        # batch_column_name - The name of the column the migration will batch over
        # job_arguments - Extra arguments to pass to the job instance when the migration runs
        # job_interval - The pause interval between each job's execution, minimum of 2 minutes
        # batch_min_value - The value in the column the batching will begin at
        # batch_max_value - The value in the column the batching will end at, defaults to `SELECT MAX(batch_column)`
        # batch_class_name - The name of the class that will be called to find the range of each next batch
        # batch_size - The maximum number of rows per job
        # sub_batch_size - The maximum number of rows processed per "iteration" within the job
        #
        #
        # *Returns the created BatchedMigration record*
        #
        # Example:
        #
        #     queue_batched_background_migration(
        #       'CopyColumnUsingBackgroundMigrationJob',
        #       :events,
        #       :id,
        #       job_interval: 2.minutes,
        #       other_job_arguments: ['column1', 'column2'])
        #
        # Where the the background migration exists:
        #
        #     class Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob
        #       def perform(start_id, end_id, batch_table, batch_column, sub_batch_size, *other_args)
        #         # do something
        #       end
        #     end
        def queue_batched_background_migration( # rubocop:disable Metrics/ParameterLists
          job_class_name,
          batch_table_name,
          batch_column_name,
          *job_arguments,
          job_interval:,
          batch_min_value: BATCH_MIN_VALUE,
          batch_max_value: nil,
          batch_class_name: BATCH_CLASS_NAME,
          batch_size: BATCH_SIZE,
          sub_batch_size: SUB_BATCH_SIZE
        )

          if Gitlab::Database::BackgroundMigration::BatchedMigration.for_configuration(job_class_name, batch_table_name, batch_column_name, job_arguments).exists?
            Gitlab::AppLogger.warn "Batched background migration not enqueued because it already exists: " \
              "job_class_name: #{job_class_name}, table_name: #{batch_table_name}, column_name: #{batch_column_name}, " \
              "job_arguments: #{job_arguments.inspect}"
            return
          end

          job_interval = BATCH_MIN_DELAY if job_interval < BATCH_MIN_DELAY

          batch_max_value ||= connection.select_value(<<~SQL)
            SELECT MAX(#{connection.quote_column_name(batch_column_name)})
            FROM #{connection.quote_table_name(batch_table_name)}
          SQL

          migration_status = batch_max_value.nil? ? :finished : :active
          batch_max_value ||= batch_min_value

          migration = Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
            job_class_name: job_class_name,
            table_name: batch_table_name,
            column_name: batch_column_name,
            job_arguments: job_arguments,
            interval: job_interval,
            min_value: batch_min_value,
            max_value: batch_max_value,
            batch_class_name: batch_class_name,
            batch_size: batch_size,
            sub_batch_size: sub_batch_size,
            status: migration_status)

          # This guard is necessary since #total_tuple_count was only introduced schema-wise,
          # after this migration helper had been used for the first time.
          return migration unless migration.respond_to?(:total_tuple_count)

          # We keep track of the estimated number of tuples to reason later
          # about the overall progress of a migration.
          migration.total_tuple_count = Gitlab::Database::PgClass.for_table(batch_table_name)&.cardinality_estimate
          migration.save!

          migration
        end

        # Force a background migration to complete.
        #
        # WARNING: This method will block the caller and move the background migration from an
        # asynchronous migration to a synchronous migration.
        #
        # 1. Steal work from sidekiq and perform immediately (avoid duplicates generated by step 2).
        # 2. Process any pending tracked jobs.
        # 3. Steal work from sidekiq and perform immediately (clear anything left from step 2).
        # 4. Optionally remove job tracking information.
        #
        # This method does not garauntee that all jobs completed successfully.
        def finalize_background_migration(class_name, delete_tracking_jobs: ['succeeded'])
          # Empty the sidekiq queue.
          Gitlab::BackgroundMigration.steal(class_name)

          # Process pending tracked jobs.
          jobs = Gitlab::Database::BackgroundMigrationJob.pending.for_migration_class(class_name)
          jobs.find_each do |job|
            BackgroundMigrationWorker.new.perform(job.class_name, job.arguments)
          end

          # Empty the sidekiq queue.
          Gitlab::BackgroundMigration.steal(class_name)

          # Delete job tracking rows.
          delete_job_tracking(class_name, status: delete_tracking_jobs) if delete_tracking_jobs
        end

        def perform_background_migration_inline?
          Rails.env.test? || Rails.env.development?
        end

        def migrate_async(*args)
          with_migration_context do
            BackgroundMigrationWorker.perform_async(*args)
          end
        end

        def migrate_in(*args)
          with_migration_context do
            BackgroundMigrationWorker.perform_in(*args)
          end
        end

        def bulk_migrate_in(*args)
          with_migration_context do
            BackgroundMigrationWorker.bulk_perform_in(*args)
          end
        end

        def bulk_migrate_async(*args)
          with_migration_context do
            BackgroundMigrationWorker.bulk_perform_async(*args)
          end
        end

        def with_migration_context(&block)
          Gitlab::ApplicationContext.with_context(caller_id: self.class.to_s, &block)
        end

        def delete_queued_jobs(class_name)
          Gitlab::BackgroundMigration.steal(class_name) do |job|
            job.delete

            false
          end
        end

        def delete_job_tracking(class_name, status: 'succeeded')
          status = Array(status).map { |s| Gitlab::Database::BackgroundMigrationJob.statuses[s] }
          jobs = Gitlab::Database::BackgroundMigrationJob.where(status: status).for_migration_class(class_name)
          jobs.each_batch { |batch| batch.delete_all }
        end

        private

        def track_in_database(class_name, arguments)
          Gitlab::Database::BackgroundMigrationJob.create!(class_name: class_name, arguments: arguments)
        end
      end
    end
  end
end
