# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      SplitAndRetryError = Class.new(StandardError)

      class BatchedJob < SharedModel
        include EachBatch
        include FromUnion

        self.table_name = :batched_background_migration_jobs

        MAX_ATTEMPTS = 3
        STUCK_JOBS_TIMEOUT = 1.hour.freeze
        TIMEOUT_EXCEPTIONS = [ActiveRecord::StatementTimeout, ActiveRecord::ConnectionTimeoutError,
                              ActiveRecord::AdapterTimeout, ActiveRecord::LockWaitTimeout].freeze

        belongs_to :batched_migration, foreign_key: :batched_background_migration_id
        has_many :batched_job_transition_logs, foreign_key: :batched_background_migration_job_id

        scope :active, -> { with_statuses(:pending, :running) }
        scope :stuck, -> { active.where('updated_at <= ?', STUCK_JOBS_TIMEOUT.ago) }
        scope :retriable, -> { from_union([with_status(:failed).where('attempts < ?', MAX_ATTEMPTS), self.stuck]) }
        scope :except_succeeded, -> { without_status(:succeeded) }
        scope :successful_in_execution_order, -> { where.not(finished_at: nil).with_status(:succeeded).order(:finished_at) }
        scope :with_preloads, -> { preload(:batched_migration) }
        scope :created_since, ->(date_time) { where('created_at >= ?', date_time) }
        scope :blocked_by_max_attempts, -> { where('attempts >= ?', MAX_ATTEMPTS) }

        state_machine :status, initial: :pending do
          state :pending, value: 0
          state :running, value: 1
          state :failed, value: 2
          state :succeeded, value: 3

          event :succeed do
            transition any => :succeeded
          end

          event :failure do
            transition any => :failed
          end

          event :run do
            transition any => :running
          end

          before_transition any => [:failed, :succeeded] do |job|
            job.finished_at = Time.current
          end

          before_transition any => :running do |job|
            job.attempts += 1
            job.started_at = Time.current
            job.finished_at = nil
            job.metrics = {}
          end

          after_transition any => :failed do |job, transition|
            error_hash = transition.args.find { |arg| arg[:error].present? }

            exception = error_hash&.fetch(:error)

            job.split_and_retry! if job.can_split?(exception)
          rescue SplitAndRetryError => error
            Gitlab::AppLogger.error(
              message: error.message,
              batched_job_id: job.id,
              batched_migration_id: job.batched_migration.id,
              job_class_name: job.migration_job_class_name,
              job_arguments: job.migration_job_arguments
            )
          end

          after_transition do |job, transition|
            error_hash = transition.args.find { |arg| arg[:error].present? }

            exception = error_hash&.fetch(:error)

            job.batched_job_transition_logs.create(previous_status: transition.from, next_status: transition.to, exception_class: exception&.class, exception_message: exception&.message)

            Gitlab::ErrorTracking.track_exception(exception, batched_job_id: job.id, job_class_name: job.migration_job_class_name, job_arguments: job.migration_job_arguments) if exception

            Gitlab::AppLogger.info(
              message: 'BatchedJob transition',
              batched_job_id: job.id,
              previous_state: transition.from_name,
              new_state: transition.to_name,
              batched_migration_id: job.batched_migration.id,
              job_class_name: job.migration_job_class_name,
              job_arguments: job.migration_job_arguments,
              exception_class: exception&.class,
              exception_message: exception&.message
            )
          end
        end

        delegate :job_class, :table_name, :column_name, :job_arguments, :job_class_name,
          to: :batched_migration, prefix: :migration

        attribute :pause_ms, :integer, default: 100

        def time_efficiency
          return unless succeeded?
          return unless finished_at && started_at

          duration = finished_at - started_at

          # TODO: Switch to individual job interval (prereq: https://gitlab.com/gitlab-org/gitlab/-/issues/328801)
          duration.to_f / batched_migration.interval
        end

        def can_split?(exception)
          attempts >= MAX_ATTEMPTS && TIMEOUT_EXCEPTIONS.include?(exception&.class) && batch_size > sub_batch_size && batch_size > 1
        end

        def split_and_retry!
          with_lock do
            raise SplitAndRetryError, 'Only failed jobs can be split' unless failed?

            new_batch_size = batch_size / 2

            break update!(attempts: 0) if new_batch_size < 1

            batching_strategy = batched_migration.batch_class.new(connection: self.class.connection)
            next_batch_bounds = batching_strategy.next_batch(
              batched_migration.table_name,
              batched_migration.column_name,
              batch_min_value: min_value,
              batch_size: new_batch_size,
              job_arguments: batched_migration.job_arguments,
              job_class: batched_migration.job_class
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
