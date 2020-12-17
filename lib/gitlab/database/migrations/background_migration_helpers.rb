# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module BackgroundMigrationHelpers
        BACKGROUND_MIGRATION_BATCH_SIZE = 1_000 # Number of rows to process per job
        BACKGROUND_MIGRATION_JOB_BUFFER_SIZE = 1_000 # Number of jobs to bulk queue at a time

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
        def bulk_queue_background_migration_jobs_by_range(model_class, job_class_name, batch_size: BACKGROUND_MIGRATION_BATCH_SIZE)
          raise "#{model_class} does not have an ID to use for batch ranges" unless model_class.column_names.include?('id')

          jobs = []
          table_name = model_class.quoted_table_name

          model_class.each_batch(of: batch_size) do |relation|
            start_id, end_id = relation.pluck("MIN(#{table_name}.id)", "MAX(#{table_name}.id)").first

            if jobs.length >= BACKGROUND_MIGRATION_JOB_BUFFER_SIZE
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
        def queue_background_migration_jobs_by_range_at_intervals(model_class, job_class_name, delay_interval, batch_size: BACKGROUND_MIGRATION_BATCH_SIZE, other_job_arguments: [], initial_delay: 0, track_jobs: false, primary_column_name: :id)
          raise "#{model_class} does not have an ID column of #{primary_column_name} to use for batch ranges" unless model_class.column_names.include?(primary_column_name.to_s)
          raise "#{primary_column_name} is not an integer column" unless model_class.columns_hash[primary_column_name.to_s].type == :integer

          # To not overload the worker too much we enforce a minimum interval both
          # when scheduling and performing jobs.
          if delay_interval < BackgroundMigrationWorker.minimum_interval
            delay_interval = BackgroundMigrationWorker.minimum_interval
          end

          final_delay = 0

          model_class.each_batch(of: batch_size) do |relation, index|
            start_id, end_id = relation.pluck(Arel.sql("MIN(#{primary_column_name}), MAX(#{primary_column_name})")).first

            # `BackgroundMigrationWorker.bulk_perform_in` schedules all jobs for
            # the same time, which is not helpful in most cases where we wish to
            # spread the work over time.
            final_delay = initial_delay + delay_interval * index
            full_job_arguments = [start_id, end_id] + other_job_arguments

            track_in_database(job_class_name, full_job_arguments) if track_jobs
            migrate_in(final_delay, job_class_name, full_job_arguments)
          end

          final_delay
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

        private

        def track_in_database(class_name, arguments)
          Gitlab::Database::BackgroundMigrationJob.create!(class_name: class_name, arguments: arguments)
        end
      end
    end
  end
end
