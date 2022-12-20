# frozen_string_literal: true

class AddPipelineHierarchySizeToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column(:plan_limits, :pipeline_hierarchy_size, :integer, default: 1000, null: false)
  end
end
