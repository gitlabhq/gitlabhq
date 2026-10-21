# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- existing module that holds the related sync services
  # Shared behavior for the sync event tables (namespaces_sync_events and
  # projects_sync_events) that queue changes for the ci and sec databases.
  module SyncEventTable
    extend ActiveSupport::Concern

    SYNC_FLAG_COLUMNS = { ci: :ci_synced, sec: :sec_synced }.freeze

    included do
      scope :unprocessed_events_for, ->(consumer) { where(SYNC_FLAG_COLUMNS.fetch(consumer) => false) }
      scope :order_by_id_asc, -> { order(id: :asc) }
    end

    class_methods do
      def mark_records_processed(records, consumer)
        id_in(records).update_all(SYNC_FLAG_COLUMNS.fetch(consumer) => true)
      end

      # The conditions under which a row is fully synced and can be deleted.
      def synced_conditions
        { ci_synced: true, sec_synced: true }
      end

      # Deletes the rows that every active consumer has synced, batched by
      # primary key so no index on the sync flag columns is needed. Returns
      # the number of deleted rows.
      def delete_synced_events(batch_size:)
        deleted = 0

        each_batch(of: batch_size) do |batch|
          deleted += batch.where(synced_conditions).delete_all
        end

        deleted
      end

      def upper_bound_count(consumer)
        unprocessed_events_for(consumer)
          .select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count').to_a.first.upper_bound_count
      end
    end
  end
end
