# frozen_string_literal: true

class ResourceWeightEvent < ResourceEvent
  include IssueResourceEvent

  validates :issue, presence: true

  after_save :usage_metrics

  private

  def usage_metrics
    Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_weight_changed_action(author: user)
  end
end
