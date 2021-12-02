# frozen_string_literal: true

class MergeRequestAssignee < ApplicationRecord
  include MergeRequestReviewerState

  belongs_to :merge_request, touch: true
  belongs_to :assignee, class_name: "User", foreign_key: :user_id, inverse_of: :merge_request_assignees

  validates :assignee, uniqueness: { scope: :merge_request_id }

  scope :in_projects, ->(project_ids) { joins(:merge_request).where(merge_requests: { target_project_id: project_ids }) }

  def set_state
    if Feature.enabled?(:mr_attention_requests, self.merge_request&.project, default_enabled: :yaml)
      self.state = MergeRequestReviewer.find_by(user_id: self.user_id, merge_request_id: self.merge_request_id)&.state || :attention_requested
    end
  end

  def cache_key
    [model_name.cache_key, id, state, assignee.cache_key]
  end
end
