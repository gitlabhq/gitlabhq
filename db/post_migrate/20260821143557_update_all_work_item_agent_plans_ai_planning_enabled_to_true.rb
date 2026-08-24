# frozen_string_literal: true

class UpdateAllWorkItemAgentPlansAiPlanningEnabledToTrue < Gitlab::Database::Migration[2.3]
  BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.4'

  def up
    define_batchable_model(:work_item_agent_plans).each_batch(of: BATCH_SIZE) do |batch|
      batch.update_all(ai_planning_enabled: true)
    end
  end

  def down
    # no-op
    # We don't want to rollback changes to this column
  end
end
