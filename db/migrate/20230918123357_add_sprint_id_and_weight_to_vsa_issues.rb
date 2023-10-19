# frozen_string_literal: true

class AddSprintIdAndWeightToVsaIssues < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :analytics_cycle_analytics_issue_stage_events, :weight, :integer
    add_column :analytics_cycle_analytics_issue_stage_events, :sprint_id, :bigint
  end

  def down
    remove_column :analytics_cycle_analytics_issue_stage_events, :sprint_id
    remove_column :analytics_cycle_analytics_issue_stage_events, :weight
  end
end
