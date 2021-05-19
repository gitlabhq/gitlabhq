# frozen_string_literal: true

class ResourceStateEvent < ResourceEvent
  include IssueResourceEvent
  include MergeRequestResourceEvent

  validate :exactly_one_issuable

  belongs_to :source_merge_request, class_name: 'MergeRequest', foreign_key: :source_merge_request_id

  # state is used for issue and merge request states.
  enum state: Issue.available_states.merge(MergeRequest.available_states).merge(reopened: 5)

  after_create :issue_usage_metrics

  def self.issuable_attrs
    %i(issue merge_request).freeze
  end

  def issuable
    issue || merge_request
  end

  def for_issue?
    issue_id.present?
  end

  private

  def issue_usage_metrics
    return unless for_issue?

    case state
    when 'closed'
      issue_usage_counter.track_issue_closed_action(author: user)
    when 'reopened'
      issue_usage_counter.track_issue_reopened_action(author: user)
    else
      # no-op, nothing to do, not a state we're tracking
    end
  end

  def issue_usage_counter
    Gitlab::UsageDataCounters::IssueActivityUniqueCounter
  end
end

ResourceStateEvent.prepend_mod_with('ResourceStateEvent')
