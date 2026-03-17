# frozen_string_literal: true

class AddFilterToIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :integrations, :filter, :jsonb, default: {}, null: false
  end
end
