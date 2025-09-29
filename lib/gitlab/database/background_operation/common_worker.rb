# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module CommonWorker
        extend ActiveSupport::Concern

        include PartitionedTable

        MINIMUM_PAUSE_MS = 100
        PARTITION_DURATION = 14.days

        REQUIRED_COLUMNS = %i[
          batch_size
          sub_batch_size
          priority
          interval
          job_class_name
          batch_class_name
          table_name
          column_name
          gitlab_schema
        ].freeze

        included do |worker_class|
          # Partition should not be changed once the record is created
          attr_readonly :partition

          REQUIRED_COLUMNS.each do |column|
            validates column, presence: true
          end

          validates :pause_ms, numericality: { greater_than_or_equal_to: MINIMUM_PAUSE_MS }

          validates :job_arguments, uniqueness: {
            scope: [:job_class_name, :table_name, :column_name]
          }

          scope :for_partition, ->(partition) { where(partition: partition) }
          scope :executable, -> { with_statuses(:queued, :active, :paused) }

          partitioned_by :partition, strategy: :sliding_list,
            next_partition_if: ->(active_partition) do
              oldest_record_in_partition = worker_class
                                             .select(:id, :created_at)
                                             .for_partition(active_partition.value)
                                             .order(:created_at)
                                             .limit(1)
                                             .take

              oldest_record_in_partition.present? &&
                oldest_record_in_partition.created_at < PARTITION_DURATION.ago
            end,
            detach_partition_if: ->(partition) do
              !worker_class
                 .for_partition(partition.value)
                 .executable
                 .exists?
            end

          state_machine :status, initial: :paused do
            state :queued, value: 0
            state :active, value: 1
            state :paused, value: 2
            state :finished, value: 3
            state :failed, value: 4
          end
        end
      end
    end
  end
end
