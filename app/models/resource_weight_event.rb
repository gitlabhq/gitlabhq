# frozen_string_literal: true

class ResourceWeightEvent < ResourceEvent
  validates :issue, presence: true

  include IssueResourceEvent
end
