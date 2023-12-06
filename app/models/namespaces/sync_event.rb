# frozen_string_literal: true

# This model serves to keep track of changes to the namespaces table in the main database, and allowing to safely
# replicate these changes to other databases.
class Namespaces::SyncEvent < ApplicationRecord
  self.table_name = 'namespaces_sync_events'

  belongs_to :namespace

  scope :unprocessed_events, -> { all }
  scope :preload_synced_relation, -> { preload(:namespace) }
  scope :order_by_id_asc, -> { order(id: :asc) }

  def self.mark_records_processed(records)
    id_in(records).delete_all
  end

  def self.enqueue_worker
    ::Namespaces::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.upper_bound_count
    select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count').to_a.first.upper_bound_count
  end
end
