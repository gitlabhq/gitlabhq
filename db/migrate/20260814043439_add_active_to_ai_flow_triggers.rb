# frozen_string_literal: true

class AddActiveToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :ai_flow_triggers, :active, :boolean, default: true, null: false
  end
end
