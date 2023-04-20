# frozen_string_literal: true

module ResourceEvents
  class MergeRequestAssignmentEvent < ApplicationRecord
    self.table_name = :merge_request_assignment_events

    belongs_to :user, optional: true
    belongs_to :merge_request

    validates :merge_request, presence: true

    enum action: { add: 1, remove: 2 }
  end
end
