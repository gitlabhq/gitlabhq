# frozen_string_literal: true

class UpdateMergeRequestsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  worker_resource_boundary :cpu
  weight 3
  loggable_arguments 2, 3, 4

  def perform(project_id, user_id, oldrev, newrev, ref, params = {})
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/24907')

    project = Project.find_by_id(project_id)
    return unless project

    user = User.find_by_id(user_id)
    return unless user

    push_options = params.with_indifferent_access[:push_options]
    gitaly_context = params.with_indifferent_access[:gitaly_context]

    MergeRequests::RefreshService
      .new(project: project, current_user: user, params: { push_options: push_options, gitaly_context: gitaly_context })
      .execute(oldrev, newrev, ref)
  end
end
