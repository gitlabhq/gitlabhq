class MergeRequestsClosingIssues < ActiveRecord::Base
  belongs_to :merge_request
  belongs_to :issue

  validates :merge_request_id, uniqueness: { scope: :issue_id }, presence: true
  validates :issue_id, presence: true

  class << self
    def count_for_collection(ids)
      select('issue_id', 'COUNT(*) as count').
        group(:issue_id).
        where(issue_id: ids)
    end
  end
end
