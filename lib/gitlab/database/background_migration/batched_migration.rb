# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedMigration < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
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

        def self.remove_toplevel_prefix(name)
          name&.sub(/\A::/, '')
        end

        def interval_elapsed?
          last_job.nil? || last_job.created_at <= Time.current - interval
        end

        def create_batched_job!(min, max)
          batched_jobs.create!(min_value: min, max_value: max, batch_size: batch_size, sub_batch_size: sub_batch_size)
        end

        def next_min_value
          last_job&.max_value&.next || min_value
        end

        def job_class
          job_class_name.constantize
        end

        def batch_class
          batch_class_name.constantize
        end

        def job_class_name=(class_name)
          write_attribute(:job_class_name, self.class.remove_toplevel_prefix(class_name))
        end

        def batch_class_name=(class_name)
          write_attribute(:batch_class_name, self.class.remove_toplevel_prefix(class_name))
        end
      end
    end
  end
end
