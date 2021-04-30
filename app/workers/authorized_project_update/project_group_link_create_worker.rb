# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectGroupLinkCreateWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id, group_id, group_access = nil)
      project = Project.find(project_id)
      group = Group.find(group_id)

      AuthorizedProjectUpdate::ProjectGroupLinkCreateService
        .new(project, group, group_access)
        .execute
    end
  end
end
