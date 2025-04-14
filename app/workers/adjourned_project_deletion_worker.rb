# frozen_string_literal: true

# rubocop:disable Scalability/IdempotentWorker -- existing class moved from EE to CE
# rubocop:disable Gitlab/BoundedContexts -- existing class moved from EE to CE
# rubocop:disable Gitlab/NamespacedClass -- existing class moved from EE to CE
class AdjournedProjectDeletionWorker
  include ApplicationWorker

  data_consistency :sticky

  sidekiq_options retry: 3
  include ExceptionBacktrace

  feature_category :groups_and_projects

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    user = project.deleting_user

    Projects::AdjournedDeletionService
      .new(project: project, current_user: user)
      .execute
  end
end
# rubocop:enable Scalability/IdempotentWorker
# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Gitlab/NamespacedClass
