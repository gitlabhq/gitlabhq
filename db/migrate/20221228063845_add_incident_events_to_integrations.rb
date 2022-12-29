# frozen_string_literal: true

class AddIncidentEventsToIntegrations < Gitlab::Database::Migration[2.1]
  def change
    add_column :integrations, :incident_events, :boolean, default: false, null: false
  end
end
