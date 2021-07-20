# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigration < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
        JOB_CLASS_MODULE = 'Gitlab::BackgroundMigration'
        BATCH_CLASS_MODULE = "#{JOB_CLASS_MODULE}::BatchingStrategies"

        self.table_name = :batched_background_migrations

        has_many :batched_jobs, foreign_key: :batched_background_migration_id
        has_one :last_job, -> { order(max_value: :desc) },
          class_name: 'Gitlab::Database::BackgroundMigration::BatchedJob',
          foreign_key: :batched_background_migration_id

        validates :job_arguments, uniqueness: {
          scope: [:job_class_name, :table_name, :column_name]
        }

        scope :queue_order, -> { order(id: :asc) }
        scope :queued, -> { where(status: [:active, :paused]) }
        scope :for_configuration, ->(job_class_name, table_name, column_name, job_arguments) do
          where(job_class_name: job_class_name, table_name: table_name, column_name: column_name)
            .where("job_arguments = ?", job_arguments.to_json) # rubocop:disable Rails/WhereEquals
        end

        enum status: {
          paused: 0,
          active: 1,
          finished: 3,
          failed: 4,
          finalizing: 5
        }

        attribute :pause_ms, :integer, default: 100

        def self.find_for_configuration(job_class_name, table_name, column_name, job_arguments)
          for_configuration(job_class_name, table_name, column_name, job_arguments).first
        end

        def self.active_migration
          active.queue_order.first
        end

        def self.successful_rows_counts(migrations)
          BatchedJob
            .succeeded
            .where(batched_background_migration_id: migrations)
            .group(:batched_background_migration_id)
            .sum(:batch_size)
        end

        def interval_elapsed?(variance: 0)
          return true unless last_job

          interval_with_variance = interval - variance
          last_job.created_at <= Time.current - interval_with_variance
        end

        def create_batched_job!(min, max)
          batched_jobs.create!(
            min_value: min,
            max_value: max,
            batch_size: batch_size,
            sub_batch_size: sub_batch_size,
            pause_ms: pause_ms
          )
        end

        def next_min_value
          last_job&.max_value&.next || min_value
        end

        def job_class
          "#{JOB_CLASS_MODULE}::#{job_class_name}".constantize
        end

        def batch_class
          "#{BATCH_CLASS_MODULE}::#{batch_class_name}".constantize
        end

        def job_class_name=(class_name)
          write_attribute(:job_class_name, class_name.demodulize)
        end

        def batch_class_name=(class_name)
          write_attribute(:batch_class_name, class_name.demodulize)
        end

        def migrated_tuple_count
          batched_jobs.succeeded.sum(:batch_size)
        end

        def prometheus_labels
          @prometheus_labels ||= {
            migration_id: id,
            migration_identifier: "%s/%s.%s" % [job_class_name, table_name, column_name]
          }
        end

        def smoothed_time_efficiency(number_of_jobs: 10, alpha: 0.2)
          jobs = batched_jobs.successful_in_execution_order.reverse_order.limit(number_of_jobs)

          return if jobs.size < number_of_jobs

          efficiencies = jobs.map(&:time_efficiency).reject(&:nil?).each_with_index

          dividend = efficiencies.reduce(0) do |total, (job_eff, i)|
            total + job_eff * (1 - alpha)**i
          end

          divisor = efficiencies.reduce(0) do |total, (job_eff, i)|
            total + (1 - alpha)**i
          end

          return if divisor == 0

          (dividend / divisor).round(2)
        end

        def optimize!
          BatchOptimizer.new(self).optimize!
        end
      end
    end
  end
end
