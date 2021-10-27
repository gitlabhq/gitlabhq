# frozen_string_literal: true

class AddStateIdToVsaIssueStageEvents < Gitlab::Database::Migration[1.0]
  def change
    add_column :analytics_cycle_analytics_issue_stage_events, :state_id, :smallint, default: 1, null: false
  end
end
