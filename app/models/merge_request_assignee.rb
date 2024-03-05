# frozen_string_literal: true

class MergeRequestAssignee < ApplicationRecord
  include EachBatch

  belongs_to :merge_request, touch: true
  belongs_to :assignee, class_name: "User", foreign_key: :user_id, inverse_of: :merge_request_assignees

  validates :assignee, uniqueness: { scope: :merge_request_id }

  scope :in_projects, ->(project_ids) { joins(:merge_request).where(merge_requests: { target_project_id: project_ids }) }
  scope :for_assignee, ->(user) { where(assignee: user) }

  def cache_key
    [model_name.cache_key, id, assignee.cache_key]
  end
end
