# frozen_string_literal: true

class ResourceStateEvent < ResourceEvent
  include IssueResourceEvent
  include MergeRequestResourceEvent

  validate :exactly_one_issuable

  belongs_to :source_merge_request, class_name: 'MergeRequest', foreign_key: :source_merge_request_id

  # state is used for issue and merge request states.
  enum state: Issue.available_states.merge(MergeRequest.available_states).merge(reopened: 5)

  def self.issuable_attrs
    %i(issue merge_request).freeze
  end
end
