# frozen_string_literal: true

module ResourceEvents
  class IssueAssignmentEvent < ApplicationRecord
    self.table_name = :issue_assignment_events

    belongs_to :user, optional: true
    belongs_to :issue

    validates :issue, presence: true

    enum action: { add: 1, remove: 2 }
  end
end
