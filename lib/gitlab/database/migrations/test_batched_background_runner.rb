# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBatchedBackgroundRunner < BaseBackgroundRunner
        include Gitlab::Database::DynamicModelHelpers

        MIGRATION_DETAILS_FILE_NAME = 'details.json'

        def initialize(result_dir:, connection:, from_id:)
          super(result_dir: result_dir, connection: connection)
          @connection = connection
          @from_id = from_id
        end

        def jobs_by_migration_name
          set_shared_model_connection do
            Gitlab::Database::BackgroundMigration::BatchedMigration
              .executable
              .where('id > ?', from_id)
              .to_h do |migration|
              batching_strategy = migration.batch_class.new(connection: connection)

              smallest_batch_start = migration.next_min_value

              table_max_value = define_batchable_model(migration.table_name, connection: connection)
                                  .maximum(migration.column_name)

              largest_batch_start = [table_max_value - migration.batch_size, smallest_batch_start].max

              # variance is the portion of the batch range that we shrink between variance * 0 and variance * 1
              # to pick actual batches to sample.
              variance = largest_batch_start - smallest_batch_start

              batch_starts = uniform_fractions
                               .lazy # frac varies from 0 to 1, values in smallest_batch_start..largest_batch_start
                               .map { |frac| (variance * frac).to_i + smallest_batch_start }

              # Track previously run batches so that we stop sampling if a new batch would intersect an older one
              completed_batches = []

              jobs_to_sample = batch_starts
                                 # Stop sampling if a batch would intersect a previous batch
                                 .take_while { |start| completed_batches.none? { |batch| batch.cover?(start) } }
                                 .map do |batch_start|
                # The current block is lazily evaluated as part of the jobs_to_sample enumerable
                # so it executes after the enclosing using_connection block has already executed
                # Therefore we need to re-associate with the explicit connection again
                Gitlab::Database::SharedModel.using_connection(connection) do
                  next_bounds = batching_strategy.next_batch(
                    migration.table_name,
                    migration.column_name,
                    batch_min_value: batch_start,
                    batch_size: migration.batch_size,
                    job_class: migration.job_class,
                    job_arguments: migration.job_arguments
                  )

                  batch_min, batch_max = next_bounds

                  job = migration.create_batched_job!(batch_min, batch_max)

                  completed_batches << (batch_min..batch_max)

                  job
                end
              end

              job_class_name = migration.job_class_name

              export_migration_details(job_class_name, migration.slice(:interval, :total_tuple_count, :max_batch_size))

              [job_class_name, jobs_to_sample]
            end
          end
        end

        def run_job(job)
          set_shared_model_connection do
            Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection).perform(job)
          end
        end

        def uniform_fractions
          Enumerator.new do |y|
            # Generates equally distributed fractions between 0 and 1, with increasing detail as more are pulled from
            # the enumerator.
            # 0, 1 (special case)
            # 1/2
            # 1/4, 3/4
            # 1/8, 3/8, 5/8, 7/8
            # etc.
            # The pattern here is at each outer loop, the denominator multiplies by 2, and at each inner loop,
            # the numerator counts up all odd numbers 1 <= n < denominator.
            y << 0
            y << 1

            # denominators are each increasing power of 2
            denominators = (1..).lazy.map { |exponent| 2**exponent }

            denominators.each do |denominator|
              # Numerators at the current step are all odd numbers between 1 and the denominator
              numerators = (1..denominator).step(2)

              numerators.each do |numerator|
                next_frac = numerator.fdiv(denominator)
                y << next_frac
              end
            end
          end
        end

        private

        attr_reader :from_id

        def set_shared_model_connection(&block)
          Gitlab::Database::SharedModel.using_connection(connection, &block)
        end

        def job_meta(job)
          set_shared_model_connection do
            job.slice(:min_value, :max_value, :batch_size, :sub_batch_size, :pause_ms)
          end
        end

        def export_migration_details(migration_name, attributes)
          directory = result_dir.join(migration_name)

          FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

          File.write(directory.join(MIGRATION_DETAILS_FILE_NAME), attributes.to_json)
        end

        def observers
          ::Gitlab::Database::Migrations::Observers.all_observers + [
            ::Gitlab::Database::Migrations::Observers::BatchDetails
          ]
        end
      end
    end
  end
end
