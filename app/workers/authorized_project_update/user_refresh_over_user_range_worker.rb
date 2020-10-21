# frozen_string_literal: true

module AuthorizedProjectUpdate
  class UserRefreshOverUserRangeWorker
    include ApplicationWorker

    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update
    deduplicate :until_executing, including_scheduled: true

    idempotent!

    def perform(start_user_id, end_user_id)
      AuthorizedProjectUpdate::RecalculateForUserRangeService.new(start_user_id, end_user_id).execute
    end
  end
end
