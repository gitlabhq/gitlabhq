# frozen_string_literal: true

class IssueRebalancingWorker
  include ApplicationWorker

  idempotent!
  urgency :low
  feature_category :issue_tracking

  def perform(issue_id)
    issue = Issue.find(issue_id)

    IssueRebalancingService.new(issue).execute
  rescue ActiveRecord::RecordNotFound, IssueRebalancingService::TooManyIssues => e
    Gitlab::ErrorTracking.log_exception(e, issue_id: issue_id)
  end
end
