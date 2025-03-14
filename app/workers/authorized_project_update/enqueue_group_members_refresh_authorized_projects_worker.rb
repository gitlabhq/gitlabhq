# frozen_string_literal: true

module AuthorizedProjectUpdate # rubocop:disable Gitlab/BoundedContexts -- keeping related workers in the same module
  class EnqueueGroupMembersRefreshAuthorizedProjectsWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :permissions
    urgency :low
    data_consistency :delayed
    queue_namespace :authorized_project_update

    idempotent!
    deduplicate :until_executing, including_scheduled: true

    def perform(group_id)
      group = Group.find_by_id(group_id)
      return unless group

      group.refresh_members_authorized_projects(
        priority: UserProjectAccessChangedService::LOW_PRIORITY
      )
    end
  end
end
