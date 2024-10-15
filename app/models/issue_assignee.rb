# frozen_string_literal: true

class IssueAssignee < ApplicationRecord
  include EachBatch

  extend SuppressCompositePrimaryKeyWarning

  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id, inverse_of: :issue_assignees

  validates :assignee, uniqueness: { scope: :issue_id }

  scope :in_projects, ->(project_ids) { joins(:issue).where(issues: { project_id: project_ids }) }
  scope :on_issues, ->(issue_ids) { where(issue_id: issue_ids) }
  scope :on_users, ->(user_ids) { where(user_id: user_ids) }
  scope :for_assignee, ->(user) { where(assignee: user) }
end

IssueAssignee.prepend_mod_with('IssueAssignee')
