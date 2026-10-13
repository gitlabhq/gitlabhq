# frozen_string_literal: true

# This model serves to keep track of changes to the namespaces table in the main database, and allowing to safely
# replicate these changes to other databases.
class Namespaces::SyncEvent < ApplicationRecord
  self.table_name = 'namespaces_sync_events'

  belongs_to :namespace

  scope :unprocessed_events, -> { where(ci_synced: false) }
  scope :preload_synced_relation, -> { preload(:namespace) }
  scope :order_by_id_asc, -> { order(id: :asc) }

  # Each mirror database marks its own column; the row is deleted once every
  # active mirror has been written. Scoped by id so no index on the flags is needed.
  def self.mark_records_processed(records)
    transaction do
      id_in(records).update_all(ci_synced: true)
      id_in(records).where(ci_synced: true).delete_all
    end
  end

  def self.enqueue_worker
    ::Namespaces::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.upper_bound_count
    unprocessed_events.select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count').to_a.first.upper_bound_count
  end
end
