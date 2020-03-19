# frozen_string_literal: true

class ResourceWeightEvent < ResourceEvent
  validates :issue, presence: true

  belongs_to :issue

  scope :by_issue, ->(issue) { where(issue_id: issue.id) }
end
