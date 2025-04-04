# frozen_string_literal: true

class AddAutomatedToResourceIterationEvent < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :resource_iteration_events, :automated, :boolean, null: false, default: false
    add_column :resource_iteration_events, :triggered_by_id, :bigint
  end
end
