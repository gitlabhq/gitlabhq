# frozen_string_literal: true

class UpdateExternalPullRequestsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management
  weight 3
  loggable_arguments 2

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
      Ci::ExternalPullRequests::CreatePipelineService.new(project, user)
        .execute(pull_request)
    end
  end
end
