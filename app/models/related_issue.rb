class RelatedIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :related_issue, class_name: 'Issue'

  validates :issue, presence: true, uniqueness: { scope: :related_issue_id }
  validates :related_issue, presence: true
end
