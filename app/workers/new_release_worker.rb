# frozen_string_literal: true

# TODO: Worker can be removed in 13.2:
# https://gitlab.com/gitlab-org/gitlab/-/issues/218231
class NewReleaseWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  queue_namespace :notifications
  feature_category :release_orchestration
  weight 2

  def perform(release_id)
    release = Release.preloaded.find_by_id(release_id)
    return unless release

    NotificationService.new.send_new_release_notifications(release)
  end
end
