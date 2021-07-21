# frozen_string_literal: true

class RepositoryCleanupWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  feature_category :source_code_management

  sidekiq_retries_exhausted do |msg, err|
    next if err.is_a?(ActiveRecord::RecordNotFound)

    args = msg['args'] + [msg['error_message']]

    new.perform_failure(*args)
  end

  def perform(project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    Projects::CleanupService.new(project, user).execute

    notification_service.repository_cleanup_success(project, user)
  end

  def perform_failure(project_id, user_id, error)
    project = Project.find(project_id)
    user = User.find(user_id)

    # Ensure the file is removed and the repository is made read-write again
    Projects::CleanupService.cleanup_after(project)

    notification_service.repository_cleanup_failure(project, user, error)
  end

  private

  def notification_service
    @notification_service ||= NotificationService.new
  end
end
