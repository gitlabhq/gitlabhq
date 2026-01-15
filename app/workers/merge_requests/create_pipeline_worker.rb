# frozen_string_literal: true

module MergeRequests
  class CreatePipelineWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 3
    sidekiq_retry_in do |_count|
      10
    end
    include PipelineQueue

    queue_namespace :pipeline_creation
    feature_category :pipeline_composition
    urgency :high
    worker_resource_boundary :cpu
    idempotent!

    sidekiq_retries_exhausted do |job, _exception|
      pipeline_creation_request = job['args'][3]&.dig('pipeline_creation_request')
      next unless pipeline_creation_request

      error_message = 'Cannot create a pipeline for this merge request after multiple retries.'

      ::Ci::PipelineCreation::Requests.failed(pipeline_creation_request, error_message)

      merge_request = ::Ci::PipelineCreation::Requests.merge_request_from_key(pipeline_creation_request['key'])

      GraphqlTriggers.ci_pipeline_creation_requests_updated(merge_request) if merge_request
    end

    def perform(project_id, user_id, merge_request_id, params = {})
      Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464679')

      project = Project.find_by_id(project_id)
      return unless project

      user = User.find_by_id(user_id)
      return unless user

      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request

      allow_duplicate = params.with_indifferent_access[:allow_duplicate]
      pipeline_creation_request = params.with_indifferent_access[:pipeline_creation_request]
      push_options = params.with_indifferent_access[:push_options]
      gitaly_context = params.with_indifferent_access[:gitaly_context]

      result = MergeRequests::CreatePipelineService
        .new(
          project: project,
          current_user: user,
          params: {
            allow_duplicate: allow_duplicate,
            pipeline_creation_request: pipeline_creation_request,
            push_options: push_options,
            gitaly_context: gitaly_context
          }
        ).execute(merge_request)

      raise StandardError, result.message if result&.error? && result.reason == :retriable_error

      merge_request.update_head_pipeline

      after_perform(merge_request)
    end

    private

    def after_perform(_merge_request)
      # overridden in EE
    end
  end
end

MergeRequests::CreatePipelineWorker.prepend_mod
