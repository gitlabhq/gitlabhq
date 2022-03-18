# frozen_string_literal: true

module IssueResourceEvent
  extend ActiveSupport::Concern

  included do
    belongs_to :issue

    scope :by_issue, ->(issue) { where(issue_id: issue.id) }

    scope :by_created_at_earlier_or_equal_to, ->(time) { where('created_at <= ?', time) }
    scope :by_issue_ids, ->(issue_ids) do
                           table = self.klass.arel_table
                           where(table[:issue_id].in(issue_ids))
                         end
  end
end
