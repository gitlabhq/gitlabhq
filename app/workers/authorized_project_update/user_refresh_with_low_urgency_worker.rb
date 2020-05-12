# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshWithLowUrgencyWorker < ::AuthorizedProjectsWorker
    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update

    idempotent!
  end
end
