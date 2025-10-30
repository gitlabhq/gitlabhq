# frozen_string_literal: true

module MergeRequests
  class ShipMergeRequestWorker
    include ApplicationWorker

    data_consistency :sticky
    idempotent!
    sidekiq_options retry: 3
    deduplicate :until_executed, if_deduplicated: :reason
    urgency :high
    worker_resource_boundary :cpu
    queue_namespace :auto_merge
    defer_on_database_health_signal :gitlab_main, [:merge_requests], 1.minute
    loggable_arguments 0

    feature_category :code_review_workflow

    def self.allowed?(merge_request:, current_user:)
      return false if Feature.disabled?(:ship_mr_quick_action, merge_request.project)

      create_pipeline_service(merge_request: merge_request, current_user: current_user)
        .allowed?(merge_request)
    end

    def self.create_pipeline_service(merge_request:, current_user:, params: {})
      ::MergeRequests::CreatePipelineService.new(
        project: merge_request.project,
        current_user: current_user,
        params: { allow_duplicate: true }.merge(params))
    end

    def perform(current_user_id, merge_request_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request

      current_user = User.find_by_id(current_user_id)
      return unless current_user

      response = create_pipeline(merge_request: merge_request, current_user: current_user)
      return response unless response.success?

      # Forcing update of merge request head pipeline after pipeline creation.
      # Without this line we'll have to wait for MergeRequests::UpdateHeadPipelineWorker
      # to react to Ci::PipelineCreatedEvent.
      merge_request.update_head_pipeline

      response = set_auto_merge(merge_request: merge_request, current_user: current_user)

      GraphqlTriggers.merge_request_merge_status_updated(merge_request)

      if response == :failed
        ServiceResponse.error(message: "Failed to enable Auto-Merge on #{merge_request.to_reference}")
      else
        ServiceResponse.success(message: "Auto-Merge enabled on #{merge_request.to_reference}")
      end
    end

    private

    def create_pipeline(merge_request:, current_user:)
      pipeline_creation_request = ::Ci::PipelineCreation::Requests.start_for_merge_request(merge_request)

      # We need to update the merge status here because a pipeline has begun creating and MRs that require a
      # successful pipeline should not be mergable at this point.
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)

      self.class.create_pipeline_service(
        merge_request: merge_request,
        current_user: current_user,
        params: { pipeline_creation_request: pipeline_creation_request })
        .execute(merge_request)
    end

    def set_auto_merge(merge_request:, current_user:)
      # Use the current diff_head_sha after pipeline creation and head pipeline update
      # to ensure the auto-merge SHA matches the actual head of the merge request
      auto_merge_params = { sha: merge_request.diff_head_sha }

      ::AutoMergeService.new(merge_request.project, current_user, auto_merge_params)
        .execute(merge_request)
    end
  end
end
