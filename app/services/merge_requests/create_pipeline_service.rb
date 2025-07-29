# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    def execute(merge_request)
      return cannot_create_pipeline_error unless can_create_pipeline_for?(merge_request)

      create_merge_request_pipeline(merge_request)
    end

    def execute_async(merge_request)
      pipeline_creation_request = ::Ci::PipelineCreation::Requests.start_for_merge_request(merge_request)

      # We need to update the merge status here because a pipeline has begun creating and MRs that require a
      # successful pipeline should not be mergable at this point.
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)

      ::MergeRequests::CreatePipelineWorker.perform_async(
        project.id, current_user.id, merge_request.id,
        params.merge(pipeline_creation_request: pipeline_creation_request).deep_stringify_keys
      )
    end

    def create_merge_request_pipeline(merge_request)
      project, ref = pipeline_project_and_ref(merge_request)

      Ci::CreatePipelineService.new(project,
        current_user,
        ref: ref,
        push_options: params[:push_options],
        pipeline_creation_request: params[:pipeline_creation_request],
        gitaly_context: params[:gitaly_context]
      ).execute(:merge_request_event, merge_request: merge_request)
    end

    def can_create_pipeline_for?(merge_request)
      ##
      # UpdateMergeRequestsWorker could be retried by an exception.
      # pipelines for merge request should not be recreated in such case.
      return false if !allow_duplicate && merge_request.find_diff_head_pipeline&.merge_request?
      return false if merge_request.has_no_commits?

      true
    end

    def allow_duplicate
      params[:allow_duplicate]
    end

    private

    def pipeline_project_and_ref(merge_request)
      if can_create_pipeline_in_target_project?(merge_request)
        [merge_request.target_project, merge_request.ref_path]
      else
        [merge_request.source_project, merge_request.source_branch_ref(or_sha: false)]
      end
    end

    def can_create_pipeline_in_target_project?(merge_request)
      target_project = merge_request.target_project

      return false unless can?(current_user, :create_pipeline, target_project)

      if merge_request.for_fork?
        return false unless target_project.ci_allow_fork_pipelines_to_run_in_parent_project?

        # skip the branch protection check for forks since the source_branch is not in the target_project
        return true
      end

      can_update_source_branch_in_target_project?(merge_request)
    end

    def can_update_source_branch_in_target_project?(merge_request)
      ::Gitlab::UserAccess.new(current_user, container: merge_request.target_project)
        .can_update_branch?(merge_request.source_branch)
    end

    def cannot_create_pipeline_error
      error_message = 'Cannot create a pipeline for this merge request.'

      ::Ci::PipelineCreation::Requests.failed(params[:pipeline_creation_request], error_message)

      ServiceResponse.error(message: error_message, payload: nil)
    end
  end
end

MergeRequests::CreatePipelineService.prepend_mod_with('MergeRequests::CreatePipelineService')
