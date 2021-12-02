# frozen_string_literal: true

class MergeRequestReviewer < ApplicationRecord
  include MergeRequestReviewerState

  belongs_to :merge_request
  belongs_to :reviewer, class_name: 'User', foreign_key: :user_id, inverse_of: :merge_request_reviewers

  def set_state
    if Feature.enabled?(:mr_attention_requests, self.merge_request&.project, default_enabled: :yaml)
      self.state = MergeRequestAssignee.find_by(user_id: self.user_id, merge_request_id: self.merge_request_id)&.state || :attention_requested
    end
  end

  def cache_key
    [model_name.cache_key, id, state, reviewer.cache_key]
  end
end
