# frozen_string_literal: true

class UpdateMergeRequestsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  weight 3
  loggable_arguments 2, 3, 4

  LOG_TIME_THRESHOLD = 90 # seconds

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(project_id, user_id, oldrev, newrev, ref)
    project = Project.find_by(id: project_id)
    return unless project

    user = User.find_by(id: user_id)
    return unless user

    MergeRequests::RefreshService.new(project, user).execute(oldrev, newrev, ref)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
