# frozen_string_literal: true

module MergeRequests
  class DisableCollaborationOnUnauthorizedWorker
    include ApplicationWorker

    data_consistency :delayed
    feature_category :code_review_workflow
    urgency :low
    idempotent!
    defer_on_database_health_signal :gitlab_main, [:merge_requests], 1.minute

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      MergeRequest.disable_collaboration_for_target_project(project)
    end
  end
end
