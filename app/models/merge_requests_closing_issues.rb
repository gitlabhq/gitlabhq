class MergeRequestsClosingIssues < ActiveRecord::Base
  belongs_to :merge_request
  belongs_to :issue

  validates_uniqueness_of :merge_request_id, scope: :issue_id

  validates_presence_of :merge_request
  validates_presence_of :issue
end
