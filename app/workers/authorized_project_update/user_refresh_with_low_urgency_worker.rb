# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshWithLowUrgencyWorker < ::AuthorizedProjectsWorker
    urgency :low
    queue_namespace :authorized_project_update

    idempotent!
  end
end
