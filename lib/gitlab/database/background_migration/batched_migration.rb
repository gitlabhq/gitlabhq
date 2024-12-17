# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigration < SharedModel
        JOB_CLASS_MODULE = 'Gitlab::BackgroundMigration'
        BATCH_CLASS_MODULE = "#{JOB_CLASS_MODULE}::BatchingStrategies"
        MAXIMUM_FAILED_RATIO = 0.5
        MINIMUM_JOBS = 50
        FINISHED_PROGRESS_VALUE = 100

        self.table_name = :batched_background_migrations

        has_many :batched_jobs, foreign_key: :batched_background_migration_id
        has_one :last_job,
          ->(relation) {
            relation.cursor? ? where.not(max_cursor: nil).order(max_cursor: :desc) : order(max_value: :desc)
          },
          class_name: 'Gitlab::Database::BackgroundMigration::BatchedJob',
          foreign_key: :batched_background_migration_id

        validates :job_arguments, uniqueness: {
          scope: [:job_class_name, :table_name, :column_name]
        }

        validate :validate_batched_jobs_status, if: -> { status_changed? && finished? }

        scope :queue_order, -> { order(id: :asc) }
        scope :queued, -> { with_statuses(:active, :paused) }
        scope :finalizing, -> { with_status(:finalizing) }
        scope :unfinished, -> { without_status(:finished, :finalized) }
        scope :ordered_by_created_at_desc, -> { order(created_at: :desc) }

        # on_hold_until is a temporary runtime status which puts execution "on hold"
        scope :executable, -> { with_status(:active).where('on_hold_until IS NULL OR on_hold_until < NOW()') }

        scope :created_after, ->(time) { where('created_at > ?', time) }

        scope :for_configuration, ->(
          gitlab_schema, job_class_name, table_name, column_name, job_arguments, include_compatible: false
        ) do
          relation = where(job_class_name: job_class_name, table_name: table_name, column_name: column_name)
            .where("job_arguments = ?", job_arguments.to_json) # rubocop:disable Rails/WhereEquals

          # This method is called from migrations older than the gitlab_schema column,
          # check and add this filter only if the column exists.
          if gitlab_schema_column_exists?
            relation = if include_compatible
                         relation.for_gitlab_schema_compatible_with(gitlab_schema)
                       else
                         relation.for_gitlab_schema(gitlab_schema)
                       end
          end

          relation
        end

        def self.gitlab_schema_column_exists?
          column_names.include?('gitlab_schema')
        end

        scope :for_gitlab_schema, ->(gitlab_schema) do
          where(gitlab_schema: gitlab_schema)
        end

        scope :for_gitlab_schema_compatible_with, ->(gitlab_schemas) do
          connection_schemas = Gitlab::Database.gitlab_schemas_for_connection(connection)
          connection_schemas_array = Arel.sql(
            "ARRAY[#{connection_schemas.map { |s| "'#{s}'" }.join(', ')}]"
          )

          gitlab_schemas = Arel.sql(
            "ARRAY[#{Array.wrap(gitlab_schemas).map { |s| "'#{s}'" }.join(', ')}]"
          )

          where("#{gitlab_schemas} <@ #{connection_schemas_array}")
            .where(gitlab_schema: connection_schemas)
        end

        state_machine :status, initial: :paused do
          state :paused, value: 0
          state :active, value: 1
          state :finished, value: 3
          state :failed, value: 4
          state :finalizing, value: 5
          state :finalized, value: 6

          event :pause do
            transition [:active, :paused] => :paused
          end

          event :execute do
            transition [:active, :paused, :failed] => :active
          end

          event :finish do
            transition [:paused, :finished, :active, :finalizing] => :finished
          end

          event :failure do
            transition [:failed, :finalizing, :active] => :failed
          end

          event :finalize do
            transition any => :finalizing
          end

          event :confirm_finalize do
            transition [:finalized, :finished] => :finalized
          end

          before_transition any => :finished do |migration|
            migration.finished_at = Time.current if migration.respond_to?(:finished_at)
          end

          before_transition any => :active do |migration|
            migration.started_at = Time.current if migration.respond_to?(:started_at)
          end
        end

        def self.valid_status
          state_machine.states.map(&:name)
        end

        def self.find_for_configuration(
          gitlab_schema, job_class_name, table_name, column_name, job_arguments, include_compatible: false
        )
          for_configuration(
            gitlab_schema, job_class_name, table_name, column_name, job_arguments,
            include_compatible: include_compatible
          ).first
        end

        def self.find_executable(id, connection:)
          for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
            .executable.find_by_id(id)
        end

        def self.active_migrations_distinct_on_table(connection:, limit:)
          distinct_on_table = select('DISTINCT ON (table_name) id')
            .for_gitlab_schema(Gitlab::Database.gitlab_schemas_for_connection(connection))
            .executable
            .order(table_name: :asc, id: :asc)

          where(id: distinct_on_table).queue_order.limit(limit)
        end

        def self.successful_rows_counts(migrations)
          BatchedJob
            .with_status(:succeeded)
            .where(batched_background_migration_id: migrations)
            .group(:batched_background_migration_id)
            .sum(:batch_size)
        end

        delegate :cursor?, to: :job_class

        def reset_attempts_of_blocked_jobs!
          batched_jobs.blocked_by_max_attempts.each_batch(of: 100) do |batch|
            batch.update_all(attempts: 0)
          end
        end

        def interval_elapsed?(variance: 0)
          return true unless last_job

          interval_with_variance = interval - variance
          last_job.created_at <= Time.current - interval_with_variance
        end

        def create_batched_job!(min, max)
          job_arguments = {
            batch_size: batch_size,
            sub_batch_size: sub_batch_size,
            pause_ms: pause_ms
          }

          if cursor?
            job_arguments[:min_cursor] = min
            job_arguments[:max_cursor] = max
          else
            job_arguments[:min_value] = min
            job_arguments[:max_value] = max
          end

          batched_jobs.create!(job_arguments)
        end

        def retry_failed_jobs!
          batched_jobs.with_status(:failed).each_batch(of: 100) do |batch|
            self.class.transaction do
              batch.lock.each(&:split_and_retry!)
              self.execute!
            end
          end

          self.execute!
        end

        def should_stop?
          return unless started_at

          total_jobs = batched_jobs.created_since(started_at).count

          return if total_jobs < MINIMUM_JOBS

          failed_jobs = batched_jobs.with_status(:failed).created_since(started_at).count

          failed_jobs.fdiv(total_jobs) > MAXIMUM_FAILED_RATIO
        end

        def next_min_value
          if cursor?
            # Cursors require a subtle off-by-one change: we return the end of the last batch instead
            # of bumping it by 1 with .next because this class doesn't know what's in the cursor.
            # This means that the min_cursor here must be logically before the beginning of the batch, not just
            # equal to the first row (if it's equal it'll make batching skip the first row), this is because the
            # KeysetIterator we use for cursor batching expects the cursor passed to it to be before the start of
            # the iteration range.
            last_job&.max_cursor || min_cursor
          else
            last_job&.max_value&.next || min_value
          end
        end

        def job_class
          "#{JOB_CLASS_MODULE}::#{job_class_name}".constantize
        end

        def batch_class
          "#{BATCH_CLASS_MODULE}::#{batch_class_name}".constantize
        end

        def job_class_name=(class_name)
          write_attribute(:job_class_name, class_name.delete_prefix("::"))
        end

        def batch_class_name=(class_name)
          write_attribute(:batch_class_name, class_name.delete_prefix("::"))
        end

        def migrated_tuple_count
          batched_jobs.with_status(:succeeded).sum(:batch_size)
        end

        def prometheus_labels
          @prometheus_labels ||= {
            migration_id: id,
            migration_identifier: "%s/%s.%s" % [job_class_name, table_name, column_name]
          }
        end

        def smoothed_time_efficiency(number_of_jobs: 10, alpha: 0.2)
          jobs = batched_jobs.successful_in_execution_order.reverse_order.limit(number_of_jobs).with_preloads

          return if jobs.size < number_of_jobs

          efficiencies = jobs.map(&:time_efficiency).reject(&:nil?).each_with_index

          dividend = efficiencies.reduce(0) do |total, (job_eff, i)|
            total + (job_eff * ((1 - alpha)**i))
          end

          divisor = efficiencies.reduce(0) do |total, (job_eff, i)|
            total + ((1 - alpha)**i)
          end

          return if divisor == 0

          (dividend / divisor).round(2)
        end

        def optimize!
          BatchOptimizer.new(self).optimize!
        end

        def health_context
          @health_context ||= Gitlab::Database::HealthStatus::Context.new(
            self,
            connection,
            [table_name]
          )
        end

        def hold!(until_time: 10.minutes.from_now)
          duration_s = (until_time - Time.current).round
          Gitlab::AppLogger.info(
            message: "#{self} put on hold until #{until_time}",
            migration_id: id,
            job_class_name: job_class_name,
            duration_s: duration_s
          )

          update!(on_hold_until: until_time)
        end

        def on_hold?
          return false unless on_hold_until

          on_hold_until > Time.zone.now
        end

        def to_s
          "BatchedMigration[id: #{id}]"
        end

        # Computes an estimation of the progress of the migration in percents.
        #
        # Because `total_tuple_count` is an estimation of the tuples based on DB statistics
        # when the migration is complete there can actually be more or less tuples that initially
        # estimated as `total_tuple_count` so the progress may not show 100%. For that reason when
        # we know migration completed successfully, we just return the 100 value
        def progress
          return FINISHED_PROGRESS_VALUE if finished? || finalized?

          return unless total_tuple_count.to_i > 0

          100 * migrated_tuple_count / total_tuple_count
        end

        def finalize_command
          <<~SCRIPT.delete("\n").squeeze(' ').strip
            sudo gitlab-rake gitlab:background_migrations:finalize
            [#{job_class_name},#{table_name},#{column_name},'#{job_arguments.to_json.gsub(',', '\,')}']
          SCRIPT
        end

        private

        def validate_batched_jobs_status
          errors.add(:batched_jobs, 'jobs need to be succeeded') if batched_jobs.except_succeeded.exists?
        end
      end
    end
  end
end
