class MergeRequestsClosingIssues < ActiveRecord::Base
  belongs_to :merge_request
  belongs_to :issue
end
