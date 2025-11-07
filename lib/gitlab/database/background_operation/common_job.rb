# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module CommonJob
        extend ActiveSupport::Concern

        include PartitionedTable

        MINIMUM_PAUSE_MS = 100
        PARTITION_DURATION = 14.days
        MAX_ATTEMPTS = 3

        REQUIRED_COLUMNS = %i[
          batch_size
          sub_batch_size
          worker_id
          worker_partition
        ].freeze

        TIMEOUT_EXCEPTIONS = [
          ActiveRecord::AdapterTimeout,
          ActiveRecord::ConnectionTimeoutError,
          ActiveRecord::QueryCanceled,
          ActiveRecord::StatementTimeout,
          ActiveRecord::LockWaitTimeout
        ].freeze

        included do |job_class|
          REQUIRED_COLUMNS.each do |column|
            validates column, presence: true
          end

          validates :pause_ms, numericality: { greater_than_or_equal_to: MINIMUM_PAUSE_MS }

          delegate :job_class, :table_name, :column_name, :job_arguments, :job_class_name,
            to: :worker, prefix: :worker

          scope :for_partition, ->(partition) { where(partition: partition) }
          scope :executable, -> { with_statuses(:pending, :running) }
          scope :failed, -> { with_status(:failed) }
          scope :running, -> { with_status(:running) }
          scope :succeeded, -> { with_status(:succeeded) }
          scope :finished, -> { where.not(finished_at: nil) }
          scope :created_since, ->(date) { where(arel_table[:created_at].gteq(date)) }
          scope :below_max_attempts, -> { where(arel_table[:attempts].lt(MAX_ATTEMPTS)) }
          scope :retriable, -> { failed.below_max_attempts }
          scope :successful_in_execution_order, -> { finished.succeeded.order_by_finished_at }
          scope :with_preloads, -> { preload(:jobs) }
          scope :order_by_finished_at, -> { order(:finished_at) }

          # Partition should not be changed once the record is created
          attr_readonly :partition

          partitioned_by :partition, strategy: :sliding_list,
            next_partition_if: ->(active_partition) do
              oldest_record_in_partition = job_class
                                             .select(:id, :created_at)
                                             .for_partition(active_partition.value)
                                             .order(:created_at)
                                             .limit(1)
                                             .take

              oldest_record_in_partition.present? && oldest_record_in_partition.created_at < PARTITION_DURATION.ago
            end,
            detach_partition_if: ->(partition) do
              !job_class
                .for_partition(partition.value)
                .executable
                .exists?
            end

          state_machine :status, initial: :pending do
            state :pending, value: 0
            state :running, value: 1
            state :failed, value: 2
            state :succeeded, value: 3

            event :run do
              transition pending: :running
            end

            event :succeed do
              transition any => :succeeded
            end

            event :failure do
              transition any => :failed
            end

            before_transition any => [:failed, :succeeded] do |job|
              job.finished_at = Time.current
            end
          end

          def first
            order(created_at: :asc).first
          end

          def last
            order(created_at: :desc).first
          end
        end
      end
    end
  end
end
