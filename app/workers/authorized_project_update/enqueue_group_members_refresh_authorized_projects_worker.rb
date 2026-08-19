# frozen_string_literal: true

module AuthorizedProjectUpdate # rubocop:disable Gitlab/BoundedContexts -- keeping related workers in the same module
  class EnqueueGroupMembersRefreshAuthorizedProjectsWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    feature_category :permissions
    urgency :low
    data_consistency :delayed
    queue_namespace :authorized_project_update

    defer_on_database_health_signal :gitlab_main, [:project_authorizations], 5.minutes

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    def perform(group_id, params = {})
      group = Group.find_by_id(group_id)
      return unless group

      group.refresh_members_authorized_projects(
        priority: params.fetch('priority', UserProjectAccessChangedService::LOW_PRIORITY).to_sym,
        direct_members_only: params.fetch('direct_members_only', false)
      )
    end
  end
end
