# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      SplitAndRetryError = Class.new(StandardError)
      ReduceSubBatchSizeError = Class.new(StandardError)

      class BatchedJob < SharedModel
        include EachBatch
        include FromUnion

        self.table_name = :batched_background_migration_jobs

        MINIMUM_BATCH_SIZE = 1
        BATCH_SIZE_DIVISOR = 2
        MINIMUM_PAUSE_MS = 100
        MAX_ATTEMPTS = 3
        MAX_SIDEKIQ_SHUTDOWN_FAILURES = 15
        MIN_BATCH_SIZE = 1
        SUB_BATCH_SIZE_REDUCE_FACTOR = 0.75
        SUB_BATCH_SIZE_THRESHOLD = 65
        STUCK_JOBS_TIMEOUT = 1.hour.freeze
        TIMEOUT_EXCEPTIONS = [ActiveRecord::StatementTimeout, ActiveRecord::ConnectionTimeoutError,
                              ActiveRecord::AdapterTimeout, ActiveRecord::LockWaitTimeout,
                              ActiveRecord::QueryCanceled].freeze

        belongs_to :batched_migration, foreign_key: :batched_background_migration_id
        has_many :batched_job_transition_logs, foreign_key: :batched_background_migration_job_id

        validates :pause_ms, numericality: { greater_than_or_equal_to: MINIMUM_PAUSE_MS }

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
            exception, from_sub_batch = job.class.extract_transition_options(transition.args)

            # For jobs that could not complete work within the shutdown timeout when Sidekiq
            # is shutting down, do not count this as an attempt.
            job.decrement!(:attempts) if job.handle_sidekiq_shutdown_failure?(exception)

            job.reduce_sub_batch_size! if from_sub_batch && job.can_reduce_sub_batch_size?

            job.split_and_retry! if job.can_split?(exception)
          rescue SplitAndRetryError, ReduceSubBatchSizeError => error
            Gitlab::AppLogger.error(
              message: error.message,
              batched_job_id: job.id,
              batched_migration_id: job.batched_migration.id,
              job_class_name: job.migration_job_class_name,
              job_arguments: job.migration_job_arguments
            )
          end

          after_transition do |job, transition|
            exception, _ = job.class.extract_transition_options(transition.args)

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

        delegate :sidekiq_shutdown_failures, to: :batched_job_transition_logs

        def self.extract_transition_options(args)
          error_hash = args.find { |arg| arg[:error].present? }

          return [] unless error_hash

          exception = error_hash.fetch(:error)
          from_sub_batch = error_hash[:from_sub_batch]

          [exception, from_sub_batch]
        end

        def job_attributes
          {
            batch_table: migration_table_name,
            batch_column: migration_column_name,
            sub_batch_size: sub_batch_size,
            pause_ms: pause_ms,
            job_arguments: migration_job_arguments
          }.tap do |attributes|
            if migration_job_class.cursor?
              attributes[:start_cursor] = min_cursor
              attributes[:end_cursor] = max_cursor
            else
              attributes[:start_id] = min_value
              attributes[:end_id] = max_value
            end
          end
        end

        def time_efficiency
          return unless succeeded?
          return unless finished_at && started_at

          duration = finished_at - started_at

          # TODO: Switch to individual job interval (prereq: https://gitlab.com/gitlab-org/gitlab/-/issues/328801)
          duration.to_f / batched_migration.interval
        end

        def can_split?(exception)
          return if still_retryable?

          exception.class.in?(TIMEOUT_EXCEPTIONS) && within_batch_size_boundaries?
        end

        def can_reduce_sub_batch_size?
          still_retryable? && within_batch_size_boundaries?
        end

        def split_and_retry!
          with_lock do
            validate_split_preconditions!

            new_batch_size = batch_size / BATCH_SIZE_DIVISOR
            next update!(attempts: 0) if new_batch_size < MINIMUM_BATCH_SIZE

            midpoint = calculate_midpoint(new_batch_size)

            if midpoint >= max_value
              update!(batch_size: new_batch_size, attempts: 0)
            else
              split_job_at_midpoint(midpoint, new_batch_size)
            end
          end
        end

        # It reduces the size of +sub_batch_size+ by 25%
        def reduce_sub_batch_size!
          raise ReduceSubBatchSizeError, 'Only sub_batch_size of failed jobs can be reduced' unless failed?

          return if sub_batch_exceeds_threshold?

          with_lock do
            actual_sub_batch_size = sub_batch_size
            reduced_sub_batch_size = (sub_batch_size * SUB_BATCH_SIZE_REDUCE_FACTOR).to_i.clamp(1, batch_size)

            update!(sub_batch_size: reduced_sub_batch_size)

            Gitlab::AppLogger.warn(
              message: 'Sub batch size reduced due to timeout',
              batched_job_id: id,
              sub_batch_size: actual_sub_batch_size,
              reduced_sub_batch_size: reduced_sub_batch_size,
              attempts: attempts,
              batched_migration_id: batched_migration.id,
              job_class_name: migration_job_class_name,
              job_arguments: migration_job_arguments
            )
          end
        end

        def still_retryable?
          attempts < MAX_ATTEMPTS
        end

        def within_batch_size_boundaries?
          batch_size > MIN_BATCH_SIZE && batch_size > sub_batch_size
        end

        # It doesn't allow sub-batch size to be reduced lower than the threshold
        #
        # @info It will prevent the next iteration to reduce the +sub_batch_size+ lower
        #       than the +SUB_BATCH_SIZE_THRESHOLD+ or 65% of its original size.
        def sub_batch_exceeds_threshold?
          initial_sub_batch_size = batched_migration.sub_batch_size
          reduced_sub_batch_size = (sub_batch_size * SUB_BATCH_SIZE_REDUCE_FACTOR).to_i
          diff = initial_sub_batch_size - reduced_sub_batch_size

          (1.0 * diff / initial_sub_batch_size * 100).round(2) > SUB_BATCH_SIZE_THRESHOLD
        end

        def sidekiq_shutdown_failures_count
          sidekiq_shutdown_failures.count
        end

        def handle_sidekiq_shutdown_failure?(exception)
          return false unless exception.is_a?(Sidekiq::Shutdown)
          return false unless attempts > 1
          return false unless sidekiq_shutdown_failures_count <= MAX_SIDEKIQ_SHUTDOWN_FAILURES

          true
        end

        private

        def validate_split_preconditions!
          raise SplitAndRetryError, 'Split and retry not yet supported for cursor based jobs' unless max_cursor.nil?
          raise SplitAndRetryError, 'Only failed jobs can be split' unless failed?
        end

        def calculate_midpoint(new_batch_size)
          batching_strategy = batched_migration.batch_class.new(connection: self.class.connection)
          next_batch_bounds = batching_strategy.next_batch(
            batched_migration.table_name,
            batched_migration.column_name,
            batch_min_value: min_value,
            batch_size: new_batch_size,
            job_arguments: batched_migration.job_arguments,
            job_class: batched_migration.job_class
          )
          next_batch_bounds.last
        end

        def split_job_at_midpoint(midpoint, new_batch_size)
          old_max_value = max_value

          update!(
            batch_size: new_batch_size,
            max_value: midpoint,
            attempts: 0,
            started_at: nil,
            finished_at: nil,
            metrics: {}
          )

          create_continuation_job(midpoint, old_max_value)
        end

        def create_continuation_job(midpoint, old_max_value)
          new_record = dup
          new_record.min_value = midpoint.next
          new_record.max_value = old_max_value
          new_record.save!
        end
      end
    end
  end
end
