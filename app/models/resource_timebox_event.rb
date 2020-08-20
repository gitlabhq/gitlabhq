# frozen_string_literal: true

class ResourceTimeboxEvent < ResourceEvent
  self.abstract_class = true

  include IssueResourceEvent
  include MergeRequestResourceEvent

  validate :exactly_one_issuable

  enum action: {
    add: 1,
    remove: 2
  }

  def self.issuable_attrs
    %i(issue merge_request).freeze
  end

  def issuable
    issue || merge_request
  end
end
