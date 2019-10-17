# frozen_string_literal: true

class NewReleaseWorker
  include ApplicationWorker

  queue_namespace :notifications

  def perform(release_id)
    release = Release.with_project_and_namespace.find_by_id(release_id)
    return unless release

    NotificationService.new.send_new_release_notifications(release)
  end
end
