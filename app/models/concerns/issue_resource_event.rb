# frozen_string_literal: true

module IssueResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :issue

    scope :by_issue, ->(issue) { where(issue_id: issue.id) }

    scope :by_issue_ids_and_created_at_earlier_or_equal_to, ->(issue_ids, time) { where(issue_id: issue_ids).where('created_at <= ?', time) }
  end
end
