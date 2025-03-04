# frozen_string_literal: true

class AddResourceMilestoneEventsUniqueParentConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  def up
    add_multi_column_not_null_constraint(:resource_milestone_events, :issue_id, :merge_request_id)
  end

  def down
    remove_multi_column_not_null_constraint(:resource_milestone_events, :issue_id, :merge_request_id)
  end
end
