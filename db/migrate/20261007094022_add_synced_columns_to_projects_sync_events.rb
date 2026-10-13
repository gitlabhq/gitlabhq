# frozen_string_literal: true

class AddSyncedColumnsToProjectsSyncEvents < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :projects_sync_events, :ci_synced, :boolean, default: false, null: false
    add_column :projects_sync_events, :sec_synced, :boolean, default: false, null: false
  end
end
