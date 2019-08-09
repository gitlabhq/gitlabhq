# frozen_string_literal: true

class UpdateExternalPullRequestsWorker
  include ApplicationWorker

  def perform(project_id, user_id, ref)
    project = Project.find_by_id(project_id)
    return unless project

    user = User.find_by_id(user_id)
    return unless user

    branch = Gitlab::Git.branch_name(ref)
    return unless branch

    external_pull_requests = project.external_pull_requests
      .by_source_repository(project.import_source)
      .by_source_branch(branch)

    external_pull_requests.find_each do |pull_request|
      ExternalPullRequests::CreatePipelineService.new(project, user)
        .execute(pull_request)
    end
  end
end
