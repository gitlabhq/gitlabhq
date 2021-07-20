# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    def execute(merge_request)
      return cannot_create_pipeline_error unless can_create_pipeline_for?(merge_request)

      create_detached_merge_request_pipeline(merge_request)
    end

    def create_detached_merge_request_pipeline(merge_request)
      Ci::CreatePipelineService.new(pipeline_project(merge_request),
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

    def pipeline_project(merge_request)
      if can_create_pipeline_in_target_project?(merge_request)
        merge_request.target_project
      else
        merge_request.source_project
      end
    end

    def pipeline_ref_for_detached_merge_request_pipeline(merge_request)
      if can_create_pipeline_in_target_project?(merge_request)
        merge_request.ref_path
      else
        merge_request.source_branch
      end
    end

    def can_create_pipeline_in_target_project?(merge_request)
      if Gitlab::Ci::Features.disallow_to_create_merge_request_pipelines_in_target_project?(merge_request.target_project)
        merge_request.for_same_project?
      else
        can?(current_user, :create_pipeline, merge_request.target_project) &&
          can_update_source_branch_in_target_project?(merge_request)
      end
    end

    def can_update_source_branch_in_target_project?(merge_request)
      ::Gitlab::UserAccess.new(current_user, container: merge_request.target_project)
        .can_update_branch?(merge_request.source_branch_ref)
    end

    def cannot_create_pipeline_error
      ServiceResponse.error(message: 'Cannot create a pipeline for this merge request.', payload: nil)
    end
  end
end

MergeRequests::CreatePipelineService.prepend_mod_with('MergeRequests::CreatePipelineService')
