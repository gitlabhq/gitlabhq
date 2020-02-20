# frozen_string_literal: true

class MergeRequestAssignee < ApplicationRecord
  belongs_to :merge_request
  belongs_to :assignee, class_name: "User", foreign_key: :user_id

  validates :assignee, uniqueness: { scope: :merge_request_id }
end
