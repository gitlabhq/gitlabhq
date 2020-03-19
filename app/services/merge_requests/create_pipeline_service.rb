# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    def execute(merge_request)
      return unless can_create_pipeline_for?(merge_request)

      create_detached_merge_request_pipeline(merge_request)
    end

    def create_detached_merge_request_pipeline(merge_request)
      Ci::CreatePipelineService.new(merge_request.source_project,
                                    current_user,
                                    ref: pipeline_ref_for_detached_merge_request_pipeline(merge_request))
        .execute(:merge_request_event, merge_request: merge_request)
    end

    def can_create_pipeline_for?(merge_request)
      ##
      # UpdateMergeRequestsWorker could be retried by an exception.
      # pipelines for merge request should not be recreated in such case.
      return false if !allow_duplicate && merge_request.find_actual_head_pipeline&.merge_request?
      return false if merge_request.has_no_commits?

      true
    end

    def allow_duplicate
      params[:allow_duplicate]
    end

    private

    def pipeline_ref_for_detached_merge_request_pipeline(merge_request)
      if can_use_merge_request_ref?(merge_request)
        merge_request.ref_path
      else
        merge_request.source_branch
      end
    end
  end
end

MergeRequests::CreatePipelineService.prepend_if_ee('EE::MergeRequests::CreatePipelineService')
