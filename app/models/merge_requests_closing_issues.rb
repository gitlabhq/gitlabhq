class MergeRequestsClosingIssues < ActiveRecord::Base
  belongs_to :merge_request
  belongs_to :issue

  validates :merge_request_id, uniqueness: { scope: :issue_id }, presence: true
  validates :issue_id, presence: true
end
