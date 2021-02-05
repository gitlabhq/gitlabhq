# frozen_string_literal: true

class AddStateToMergeRequestReviewers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  REVIEW_DEFAULT_STATE = 0

  def change
    add_column :merge_request_reviewers, :state, :smallint, default: REVIEW_DEFAULT_STATE, null: false
  end
end
