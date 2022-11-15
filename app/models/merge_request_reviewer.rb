# frozen_string_literal: true

class MergeRequestReviewer < ApplicationRecord
  include MergeRequestReviewerState
  include BulkInsertSafe # must be included _last_ i.e. after any other concerns

  belongs_to :merge_request
  belongs_to :reviewer, class_name: 'User', foreign_key: :user_id, inverse_of: :merge_request_reviewers

  def cache_key
    [model_name.cache_key, id, state, reviewer.cache_key]
  end
end
