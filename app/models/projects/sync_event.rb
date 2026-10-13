# frozen_string_literal: true

# This model serves to keep track of changes to the namespaces table in the main database as they relate to projects,
# allowing to safely replicate changes to other databases.
class Projects::SyncEvent < ApplicationRecord
  self.table_name = 'projects_sync_events'

  belongs_to :project

  scope :unprocessed_events, -> { where(ci_synced: false) }
  scope :preload_synced_relation, -> { preload(:project) }
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
    ::Projects::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.upper_bound_count
    unprocessed_events.select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count').to_a.first.upper_bound_count
  end
end
