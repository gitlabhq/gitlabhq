# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectCreateWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :authentication_and_authorization
    urgency :low
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id)
      project = Project.find(project_id)

      AuthorizedProjectUpdate::ProjectCreateService.new(project).execute
    end
  end
end
