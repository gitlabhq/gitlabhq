# frozen_string_literal: true

module MergeRequests
  class CreatePipelineWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include PipelineQueue

    queue_namespace :pipeline_creation
    feature_category :continuous_integration
    urgency :high
    worker_resource_boundary :cpu
    idempotent!

    def perform(project_id, user_id, merge_request_id, params = {})
      project = Project.find_by_id(project_id)
      return unless project

      user = User.find_by_id(user_id)
      return unless user

      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request

      allow_duplicate = params.with_indifferent_access[:allow_duplicate]
      push_options = params.with_indifferent_access[:push_options]

      MergeRequests::CreatePipelineService
        .new(
          project: project,
          current_user: user,
          params: { allow_duplicate: allow_duplicate, push_options: push_options }
        ).execute(merge_request)

      merge_request.update_head_pipeline
    end
  end
end
