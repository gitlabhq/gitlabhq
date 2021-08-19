# frozen_string_literal: true

class UpdateMergeRequestsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review
  urgency :high
  worker_resource_boundary :cpu
  weight 3
  loggable_arguments 2, 3, 4

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    MergeRequests::RefreshService.new(project: project, current_user: user).execute(oldrev, newrev, ref)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
