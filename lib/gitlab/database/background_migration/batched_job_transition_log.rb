# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundMigration
      class BatchedJobTransitionLog < ApplicationRecord
        include PartitionedTable

        self.table_name = :batched_background_migration_job_transition_logs

        partitioned_by :created_at, strategy: :monthly, retain_for: 6.months

        belongs_to :batched_job, foreign_key: :batched_background_migration_job_id

        validates :previous_status, :next_status, :batched_job, presence: true

        validates :exception_class, length: { maximum: 100 }
        validates :exception_message, length: { maximum: 1000 }

        enum previous_status: BatchedJob.statuses, _prefix: true
        enum next_status: BatchedJob.statuses, _prefix: true
      end
    end
  end
end
