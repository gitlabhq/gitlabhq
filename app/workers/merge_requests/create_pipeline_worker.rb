# frozen_string_literal: true

module MergeRequests
  class CreatePipelineWorker
    include ApplicationWorker
    include PipelineQueue

    PipelineCreationRetryError = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

    data_consistency :sticky

    sidekiq_options retry: 3
    sidekiq_retry_in do |_count|
      10
    end

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
      defer_request_completion = params.with_indifferent_access[:defer_request_completion]

      result = MergeRequests::CreatePipelineService
        .new(
          project: project,
          current_user: user,
          params: {
            allow_duplicate: allow_duplicate,
            pipeline_creation_request: pipeline_creation_request,
            push_options: push_options,
            gitaly_context: gitaly_context,
            defer_request_completion: defer_request_completion
          }
        ).execute(merge_request)

      raise PipelineCreationRetryError, result.message if result&.error? && result.reason == :retriable_error

      merge_request.update_head_pipeline

      complete_pipeline_creation_request(result, pipeline_creation_request, merge_request) if defer_request_completion

      after_perform(merge_request)
    end

    private

    def complete_pipeline_creation_request(result, pipeline_creation_request, merge_request)
      if result.error?
        error_message = result.message
        ::Ci::PipelineCreation::Requests.failed(pipeline_creation_request, error_message)
      else
        ::Ci::PipelineCreation::Requests.succeeded(pipeline_creation_request, result.payload.id)
      end

      GraphqlTriggers.ci_pipeline_creation_requests_updated(merge_request)
    end

    def after_perform(merge_request)
      publish_pipeline_creation_completed_event(merge_request)
    end

    # Publish AFTER `update_head_pipeline` has run in `perform`, so
    # `merge_request.diff_head_pipeline` reflects whether a pipeline was
    # persisted for the current diff head. Subscribers (e.g.
    # ProcessAutoMergeFromEventWorker) use the `pipeline_id` field to
    # distinguish "no pipeline created" from "pipeline created".
    def publish_pipeline_creation_completed_event(merge_request)
      return unless ::Feature.enabled?(:trigger_auto_merge_after_pipeline_creation, merge_request.project)

      ::Gitlab::EventStore.publish(
        ::MergeRequests::PipelineCreationCompletedEvent.new(data: {
          merge_request_id: merge_request.id,
          project_id: merge_request.project_id,
          pipeline_id: merge_request.diff_head_pipeline&.id
        }.compact)
      )
    end
  end
end

MergeRequests::CreatePipelineWorker.prepend_mod
