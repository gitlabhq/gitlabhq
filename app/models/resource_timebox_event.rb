# frozen_string_literal: true

class ResourceTimeboxEvent < ResourceEvent
  include MergeRequestResourceEvent
  include Importable

  self.abstract_class = true

  validate :exactly_one_issuable, unless: :importing?

  enum action: {
    add: 1,
    remove: 2
  }

  after_create :issue_usage_metrics

  def self.issuable_attrs
    %i[issue merge_request].freeze
  end

  def issuable
    issue || merge_request
  end

  private

  def for_issue?
    issue_id.present?
  end

  def issue_usage_metrics
    return unless for_issue?

    case self
    when ResourceMilestoneEvent
      Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_milestone_changed_action(
        author: user, project: issue.project
      )
    else
      # no-op
    end
  end
end

ResourceTimeboxEvent.prepend_mod_with('ResourceTimeboxEvent')
