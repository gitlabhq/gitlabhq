# frozen_string_literal: true

class AddReadinessScoreToWorkItemAgentPlans < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :work_item_agent_plans, :readiness_score, :smallint
  end
end
