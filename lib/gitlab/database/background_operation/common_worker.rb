# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      module CommonWorker
        extend ActiveSupport::Concern

        include PartitionedTable
        include FromUnion

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
          scope :unfinished, -> { with_statuses(:queued, :active, :paused) }
          scope :with_job_arguments, ->(args) { where("job_arguments = ?", args.to_json) } # rubocop:disable Rails/WhereEquals -- to override Rails comparison
          scope :not_on_hold, -> { where('on_hold_until IS NULL OR on_hold_until < NOW()') }

          scope :executable, -> do
            with_statuses(:queued, :paused).not_on_hold
          end

          scope :unfinished_with_config, ->(job_class_name, table_name, column_name, job_arguments, org_id: nil) do
            config = {
              job_class_name: job_class_name,
              table_name: table_name,
              column_name: column_name
            }

            config = config.merge(organization_id: org_id) if org_id.present?

            unfinished.with_job_arguments(job_arguments).where(config)
          end

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
                 .unfinished
                 .exists?
            end

          state_machine :status, initial: :queued do
            state :queued, value: 0
            state :active, value: 1
            state :paused, value: 2
            state :finished, value: 3
            state :failed, value: 4
          end
        end

        class_methods do
          def schedulable_workers(limit)
            unions = Gitlab::Database::PostgresPartitionedTable.each_partition(table_name).map do |partition|
              partition_name = partition.name

              select('id, partition, created_at')
                .from("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition_name} AS #{table_name}")
                .executable
                .order(created_at: :asc)
                .limit(limit)
            end

            select('id, partition')
              .from_union(unions, remove_duplicates: false, remove_order: false)
              .order(partition: :asc, created_at: :asc)
              .limit(limit)
          end
        end
      end
    end
  end
end
