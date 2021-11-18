# frozen_string_literal: true
class AddStateToMergeRequestAssignees < Gitlab::Database::Migration[1.0]
  REVIEW_DEFAULT_STATE = 0

  def change
    add_column :merge_request_assignees, :state, :smallint, default: REVIEW_DEFAULT_STATE, null: false
  end
end
