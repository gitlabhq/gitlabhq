# frozen_string_literal: true

class IssueRebalancingWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  idempotent!
  urgency :low
  feature_category :issue_tracking
  tags :exclude_from_kubernetes

  def perform(ignore = nil, project_id = nil)
    return if project_id.nil?

    project = Project.find(project_id)

    # Temporary disable reabalancing for performance reasons
    # For more information check https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4321
    return if project.root_namespace&.issue_repositioning_disabled?

    # All issues are equivalent as far as we are concerned
    issue = project.issues.take # rubocop: disable CodeReuse/ActiveRecord

    IssueRebalancingService.new(issue).execute
  rescue ActiveRecord::RecordNotFound, IssueRebalancingService::TooManyIssues => e
    Gitlab::ErrorTracking.log_exception(e, project_id: project_id)
  end
end
