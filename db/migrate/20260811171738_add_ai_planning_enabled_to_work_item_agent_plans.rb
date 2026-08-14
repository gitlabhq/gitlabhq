# frozen_string_literal: true

class AddAiPlanningEnabledToWorkItemAgentPlans < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :work_item_agent_plans, :ai_planning_enabled, :boolean, null: false, default: false, if_not_exists: true
  end
end
