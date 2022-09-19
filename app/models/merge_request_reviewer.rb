# frozen_string_literal: true

class MergeRequestReviewer < ApplicationRecord
  include MergeRequestReviewerState
  include IgnorableColumns
  ignore_column :updated_state_by_user_id, remove_with: '15.6', remove_after: '2022-10-22'

  belongs_to :merge_request
  belongs_to :reviewer, class_name: 'User', foreign_key: :user_id, inverse_of: :merge_request_reviewers

  def cache_key
    [model_name.cache_key, id, state, reviewer.cache_key]
  end
end
