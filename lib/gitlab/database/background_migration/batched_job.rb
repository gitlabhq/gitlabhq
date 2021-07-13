# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedJob < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
        include FromUnion

        self.table_name = :batched_background_migration_jobs

        MAX_ATTEMPTS = 3
        STUCK_JOBS_TIMEOUT = 1.hour.freeze

        belongs_to :batched_migration, foreign_key: :batched_background_migration_id

        scope :active, -> { where(status: [:pending, :running]) }
        scope :stuck, -> { active.where('updated_at <= ?', STUCK_JOBS_TIMEOUT.ago) }
        scope :retriable, -> {
          failed_jobs = where(status: :failed).where('attempts < ?', MAX_ATTEMPTS)

          from_union([failed_jobs, self.stuck])
        }

        enum status: {
          pending: 0,
          running: 1,
          failed: 2,
          succeeded: 3
        }

        scope :successful_in_execution_order, -> { where.not(finished_at: nil).succeeded.order(:finished_at) }

        delegate :job_class, :table_name, :column_name, :job_arguments,
          to: :batched_migration, prefix: :migration

        attribute :pause_ms, :integer, default: 100

        def time_efficiency
          return unless succeeded?
          return unless finished_at && started_at

          duration = finished_at - started_at

          # TODO: Switch to individual job interval (prereq: https://gitlab.com/gitlab-org/gitlab/-/issues/328801)
          duration.to_f / batched_migration.interval
        end

        def split_and_retry!
          with_lock do
            raise 'Only failed jobs can be split' unless failed?

            new_batch_size = batch_size / 2

            raise 'Job cannot be split further' if new_batch_size < 1

            batching_strategy = batched_migration.batch_class.new
            next_batch_bounds = batching_strategy.next_batch(
              batched_migration.table_name,
              batched_migration.column_name,
              batch_min_value: min_value,
              batch_size: new_batch_size
            )
            midpoint = next_batch_bounds.last

            # We don't want the midpoint to go over the existing max_value because
            # those IDs would already be in the next batched migration job.
            # This could happen when a lot of records in the current batch are deleted.
            #
            # In this case, we just lower the batch size so that future calls to this
            # method could eventually split the job if it continues to fail.
            if midpoint >= max_value
              update!(batch_size: new_batch_size, attempts: 0)
            else
              old_max_value = max_value

              update!(
                batch_size: new_batch_size,
                max_value: midpoint,
                attempts: 0,
                started_at: nil,
                finished_at: nil,
                metrics: {}
              )

              new_record = dup
              new_record.min_value = midpoint.next
              new_record.max_value = old_max_value
              new_record.save!
            end
          end
        end
      end
    end
  end
end
