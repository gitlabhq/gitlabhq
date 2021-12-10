# frozen_string_literal: true

# This model serves to keep track of changes to the namespaces table in the main database, and allowing to safely
# replicate these changes to other databases.
class Namespaces::SyncEvent < ApplicationRecord
  self.table_name = 'namespaces_sync_events'

  belongs_to :namespace

  scope :preload_synced_relation, -> { preload(:namespace) }
  scope :order_by_id_asc, -> { order(id: :asc) }

  def self.enqueue_worker
    ::Namespaces::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker
  end
end
