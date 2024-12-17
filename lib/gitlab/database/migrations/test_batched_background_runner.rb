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

        # rubocop:disable Metrics/AbcSize -- This method is temporarily more complex while it deals with both cursor
        # and non-cursor migrations. The complexity will significantly decrease when non-cursor migration support is
        # removed.
        def jobs_by_migration_name
          set_shared_model_connection do
            Gitlab::Database::BackgroundMigration::BatchedMigration
              .executable
              .where('id > ?', from_id)
              .to_h do |migration|
              batching_strategy = migration.batch_class.new(connection: connection)

              is_cursor = migration.cursor?

              # Pretend every migration is a cursor migration. When actually running the job,
              # we can unwrap the cursor if it is not.
              cursor_columns = is_cursor ? migration.job_class.cursor_columns : [migration.column_name]

              # Wrap the single result into an array (that we pretend is a cursor) if this
              # is not a cursor migration. (next_min_value has an if check on cursor? and returns either array or int)
              table_min_cursor = Array.wrap(migration.next_min_value)

              ordering = cursor_columns.map { |c| { c => :desc } }

              rows_ordered_backwards = define_batchable_model(migration.table_name, connection: connection)
                                        .order(*ordering)
              # If only one column, pluck.first returns a single value for that column instead of an array of
              # all (1) column(s)
              # So wrap the result for consistency between 1 and many columns
              table_max_cursor = Array.wrap(rows_ordered_backwards.pick(*cursor_columns))

              # variance is the portion of the batch range that we shrink between variance * 0 and variance * 1
              # to pick actual batches to sample.

              # Here we're going to do something that is explicitly WRONG, but good enough - we assume that we can
              # just scale the first element of the cursor to get a reasonable percentage of the way through the table.
              # This is really not true at all, but it's close enough for testing.
              # For the rest of the components of our example cursors, we'll reuse parts of the end cursors for each
              # batch for the start cursors of the next batch
              variance = table_max_cursor[0] - table_min_cursor[0]

              batch_first_elems = uniform_fractions.lazy.map { |frac| (variance * frac).to_i }

              jobs_to_sample = Enumerator.new do |y|
                completed_batches = []
                # We construct the starting cursor from the end of the prev loop,
                # or just the beginning of the table on the first loop
                # This way, cursors for our batches start at interesting places in all of their positions
                prev_end_cursor = table_min_cursor

                loop do
                  first_elem = batch_first_elems.next
                  batch_start = [first_elem] + prev_end_cursor[1..]
                  break if completed_batches.any? { |batch| batch.cover?(batch_start) }

                  # The current block is lazily evaluated as part of the jobs_to_sample enumerable
                  # so it executes after the enclosing using_connection block has already executed
                  # Therefore we need to re-associate with the explicit connection again
                  Gitlab::Database::SharedModel.using_connection(connection) do
                    next_bounds = batching_strategy.next_batch(
                      migration.table_name,
                      migration.column_name,
                      batch_min_value: is_cursor ? batch_start : batch_start[0],
                      batch_size: migration.batch_size,
                      job_class: migration.job_class,
                      job_arguments: migration.job_arguments
                    )

                    # If no rows match, the next_bounds are nil.
                    # This will only happen if there are zero rows to match from the current sampling point to the end
                    # of the table
                    # Simulate the approach in the actual background migration worker by not sampling a batch
                    # from this range.
                    # (The actual worker would finish the migration, but we may find batches that can be sampled
                    # elsewhere in the table)
                    if next_bounds.nil?
                      # If the migration has no work to do across the entire table, sampling can get stuck
                      # in a loop if we don't mark the attempted batches as completed
                      # We need to guess a size for this. The batch size of the migration is way too big in all
                      # cases with a 2-element or more cursor, but it doesn't really matter so we just guess that.
                      synthetic_cursor_offset = migration.batch_size
                      batch_end = batch_start.dup
                      batch_end[0] += synthetic_cursor_offset
                      completed_batches << (batch_start..batch_end)
                      next
                    end

                    batch_min, batch_max = next_bounds

                    # These are ints if not a cursor, wrap them to maintain the illusion that everything is a cursor

                    job = migration.create_batched_job!(batch_min, batch_max)

                    # Wrap the batch min/max back as cursors if the migration was not cursor-based
                    batch_min = Array.wrap(batch_min)
                    batch_max = Array.wrap(batch_max)

                    # Save the max as cursor details for the next loop so that we test
                    # interesting cursor positions.
                    prev_end_cursor = batch_max

                    completed_batches << (batch_min..batch_max)

                    y << job
                  end
                end
              end

              job_class_name = migration.job_class_name

              export_migration_details(job_class_name,
                migration.slice(:interval, :total_tuple_count, :max_batch_size))

              [job_class_name, jobs_to_sample]
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def run_job(job)
          set_shared_model_connection do
            Gitlab::Database::BackgroundMigration::BatchedMigrationWrapper.new(connection: connection).perform(job)
          end
        end

        def print_job_progress(batch_name, job)
          args_phrase = if job.batched_migration.cursor?
                          "#{job.min_cursor} - #{job.max_cursor}"
                        else
                          "#{job.min_value} - #{job.max_value}"
                        end

          puts("  #{batch_name} (#{args_phrase})") # rubocop:disable Rails/Output -- This runs only in pipelines and should output to the pipeline log
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
