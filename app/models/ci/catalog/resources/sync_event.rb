# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This table is used as a queue of catalog resources that need to be synchronized with `projects`.
      # A PG trigger adds a SyncEvent when the associated `projects` record of a catalog resource
      # updates any of the relevant columns referenced in `Ci::Catalog::Resource#sync_with_project`
      # (DB function name: `insert_catalog_resource_sync_event`).
      class SyncEvent < ::ApplicationRecord
        include PartitionedTable

        PARTITION_DURATION = 1.day

        self.table_name = 'p_catalog_resource_sync_events'
        self.primary_key = :id
        self.sequence_name = :p_catalog_resource_sync_events_id_seq

        ignore_column :partition_id, remove_never: true

        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :sync_events
        belongs_to :project, inverse_of: :catalog_resource_sync_events

        scope :for_partition, ->(partition) { where(partition_id: partition) }
        scope :select_with_partition,
          -> { select(:id, :catalog_resource_id, arel_table[:partition_id].as('partition')) }

        scope :unprocessed_events, -> { select_with_partition.status_pending }
        scope :preload_synced_relation, -> { preload(catalog_resource: :project) }

        enum status: { pending: 1, processed: 2 }, _prefix: :status

        partitioned_by :partition_id, strategy: :sliding_list,
          next_partition_if: ->(active_partition) do
            oldest_record_in_partition = Ci::Catalog::Resources::SyncEvent
              .select(:id, :created_at)
              .for_partition(active_partition.value)
              .order(:id)
              .limit(1)
              .take

            oldest_record_in_partition.present? &&
              oldest_record_in_partition.created_at < PARTITION_DURATION.ago
          end,
          detach_partition_if: ->(partition) do
            !Ci::Catalog::Resources::SyncEvent
              .for_partition(partition.value)
              .status_pending
              .exists?
          end

        class << self
          def mark_records_processed(records)
            update_by_partition(records) do |partitioned_scope|
              partitioned_scope.update_all(status: :processed)
            end
          end

          def enqueue_worker
            ::Ci::Catalog::Resources::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker -- Worker is scheduled in model callback functions
          end

          def upper_bound_count
            select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count')
              .status_pending.to_a.first.upper_bound_count
          end

          private

          # You must use .select_with_partition before calling this method
          # as it requires the partition to be explicitly selected.
          def update_by_partition(records)
            records.group_by(&:partition).each do |partition, records_within_partition|
              partitioned_scope = status_pending
                .for_partition(partition)
                .where(id: records_within_partition.map(&:id))

              yield(partitioned_scope)
            end
          end
        end
      end
    end
  end
end
