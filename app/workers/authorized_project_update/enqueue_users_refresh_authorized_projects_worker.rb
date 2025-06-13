# frozen_string_literal: true

module AuthorizedProjectUpdate # rubocop:disable Gitlab/BoundedContexts -- keeping related workers in the same module
  class EnqueueUsersRefreshAuthorizedProjectsWorker
    include ApplicationWorker

    feature_category :permissions
    urgency :low
    data_consistency :delayed
    queue_namespace :authorized_project_update

    defer_on_database_health_signal :gitlab_main, [:project_authorizations], 1.minute

    idempotent!
    deduplicate :until_executing, including_scheduled: true

    def perform(user_ids)
      return unless user_ids.present?

      UserProjectAccessChangedService.new(user_ids).execute(
        priority: UserProjectAccessChangedService::LOW_PRIORITY
      )
    end
  end
end
