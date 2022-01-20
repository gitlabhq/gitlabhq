# frozen_string_literal: true

class AddArchiveTraceEventsToIntegrations < Gitlab::Database::Migration[1.0]
  def change
    add_column :integrations, :archive_trace_events, :boolean, null: false, default: false
  end
end
