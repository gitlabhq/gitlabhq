# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigration < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
        JOB_CLASS_MODULE = 'Gitlab::BackgroundMigration'
        BATCH_CLASS_MODULE = "#{JOB_CLASS_MODULE}::BatchingStrategies"

        self.table_name = :batched_background_migrations

        has_many :batched_jobs, foreign_key: :batched_background_migration_id
        has_one :last_job, -> { order(id: :desc) },
          class_name: 'Gitlab::Database::BackgroundMigration::BatchedJob',
          foreign_key: :batched_background_migration_id

        scope :queue_order, -> { order(id: :asc) }

        enum status: {
          paused: 0,
          active: 1,
          aborted: 2,
          finished: 3
        }

        def self.active_migration
          active.queue_order.first
        end

        def interval_elapsed?(variance: 0)
          return true unless last_job

          interval_with_variance = interval - variance
          last_job.created_at <= Time.current - interval_with_variance
        end

        def create_batched_job!(min, max)
          batched_jobs.create!(min_value: min, max_value: max, batch_size: batch_size, sub_batch_size: sub_batch_size)
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

        def prometheus_labels
          @prometheus_labels ||= {
            migration_id: id,
            migration_identifier: "%s/%s.%s" % [job_class_name, table_name, column_name]
          }
        end
      end
    end
  end
end
