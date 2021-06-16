# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshFromReplicaWorker < ::AuthorizedProjectsWorker
    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update
    deduplicate :until_executing, including_scheduled: true

    idempotent!

    # This worker will start reading data from the replica database soon
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/333219
  end
end
