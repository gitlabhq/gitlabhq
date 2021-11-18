# frozen_string_literal: true

class CreatePipelineTriggersApplicationLimits < Gitlab::Database::Migration[1.0]
  def change
    add_column(:plan_limits, :pipeline_triggers, :integer, default: 25_000, null: false)
  end
end
