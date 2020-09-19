# frozen_string_literal: true

class IssueRebalancingWorker
  include ApplicationWorker

  idempotent!
  urgency :low
  feature_category :issue_tracking

  def perform(ignore = nil, project_id = nil)
    return if project_id.nil?

    project = Project.find(project_id)
    issue = project.issues.first # All issues are equivalent as far as we are concerned

    IssueRebalancingService.new(issue).execute
  rescue ActiveRecord::RecordNotFound, IssueRebalancingService::TooManyIssues => e
    Gitlab::ErrorTracking.log_exception(e, project_id: project_id)
  end
end
