# frozen_string_literal: true

class RepositoryCleanupWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include Sidekiq::InterruptionsExhausted

  MAX_INTERRUPTIONS_ERROR_MESSAGE = 'The cleanup job was interrupted too many times and could not complete. ' \
    'Please try again.'

  data_consistency :always

  sidekiq_options retry: 3
  feature_category :source_code_management

  sidekiq_retries_exhausted do |msg, _err|
    new.perform_failure(*msg['args'], msg['error_message'])
  end

  sidekiq_interruptions_exhausted do |job|
    new.perform_failure(*job['args'], MAX_INTERRUPTIONS_ERROR_MESSAGE)
  end

  def perform(project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    Projects::CleanupService.new(project, user).execute

    notification_service.repository_cleanup_success(project, user)
  end

  def perform_failure(project_id, user_id, error)
    project = Project.find_by_id(project_id)
    return unless project

    project.set_repository_writable!
    remove_bfg_object_map(project)

    user = User.find_by_id(user_id)
    return unless user

    notification_service.repository_cleanup_failure(project, user, error)
  end

  private

  def remove_bfg_object_map(project)
    project.bfg_object_map.remove!
  rescue StandardError => e
    # Don't let a failed map removal skip the failure notification.
    Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
  end

  def notification_service
    @notification_service ||= NotificationService.new
  end
end
