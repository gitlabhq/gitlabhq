# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectGroupLinkCreateWorker
    include ApplicationWorker

    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id, group_id)
      project = Project.find(project_id)
      group = Group.find(group_id)

      AuthorizedProjectUpdate::ProjectGroupLinkCreateService.new(project, group)
                                                            .execute
    end
  end
end
