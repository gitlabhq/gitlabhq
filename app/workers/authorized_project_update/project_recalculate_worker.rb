# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
    end
  end
end
