# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    def execute(merge_request)
      return unless can_create_pipeline_for?(merge_request)

      create_detached_merge_request_pipeline(merge_request)
    end

    def create_detached_merge_request_pipeline(merge_request)
      if can_use_merge_request_ref?(merge_request)
        Ci::CreatePipelineService.new(merge_request.source_project, current_user,
                                      ref: merge_request.ref_path)
          .execute(:merge_request_event, merge_request: merge_request)
      else
        Ci::CreatePipelineService.new(merge_request.source_project, current_user,
                                      ref: merge_request.source_branch)
          .execute(:merge_request_event, merge_request: merge_request)
      end
    end

    def can_create_pipeline_for?(merge_request)
      ##
      # UpdateMergeRequestsWorker could be retried by an exception.
      # pipelines for merge request should not be recreated in such case.
      return false if !allow_duplicate && merge_request.find_actual_head_pipeline&.triggered_by_merge_request?
      return false if merge_request.has_no_commits?

      true
    end

    def allow_duplicate
      params[:allow_duplicate]
    end
  end
end
