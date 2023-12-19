# frozen_string_literal: true

# This model serves to keep track of changes to the namespaces table in the main database as they relate to projects,
# allowing to safely replicate changes to other databases.
class Projects::SyncEvent < ApplicationRecord
  self.table_name = 'projects_sync_events'

  belongs_to :project

  scope :unprocessed_events, -> { all }
  scope :preload_synced_relation, -> { preload(:project) }
  scope :order_by_id_asc, -> { order(id: :asc) }

  def self.mark_records_processed(records)
    id_in(records).delete_all
  end

  def self.enqueue_worker
    ::Projects::ProcessSyncEventsWorker.perform_async # rubocop:disable CodeReuse/Worker
  end

  def self.upper_bound_count
    select('COALESCE(MAX(id) - MIN(id) + 1, 0) AS upper_bound_count').to_a.first.upper_bound_count
  end
end
