# frozen_string_literal: true

class AddEventFiltersToIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :integrations, :event_filters, :jsonb, default: {}, null: false
  end
end
