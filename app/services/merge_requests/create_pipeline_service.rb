# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    def execute(merge_request)
      return cannot_create_pipeline_error('no commits to build') if merge_request.has_no_commits?

      duplicate_error = check_duplicate_pipeline(merge_request)
      return duplicate_error if duplicate_error

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

      GraphqlTriggers.ci_pipeline_creation_requests_updated(merge_request)
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

    def allowed?(merge_request)
      can_create_pipeline_for?(merge_request) && user_can_run_pipeline?(merge_request)
    end

    def allow_duplicate
      params[:allow_duplicate]
    end

    private

    def can_create_pipeline_for?(merge_request)
      ##
      # UpdateMergeRequestsWorker could be retried by an exception.
      # pipelines for merge request should not be recreated in such case.
      return false if !allow_duplicate && merge_request.find_diff_head_pipeline&.merge_request?
      return false if merge_request.has_no_commits?

      true
    end

    def user_can_run_pipeline?(merge_request)
      current_user.can?(:create_pipeline, pipeline_project(merge_request))
    end

    def pipeline_project(merge_request)
      pipeline_project_and_ref(merge_request).first
    end

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

    def check_duplicate_pipeline(merge_request)
      return if allow_duplicate

      existing_pipeline = merge_request.find_diff_head_pipeline
      return unless existing_pipeline
      return unless existing_pipeline.merge_request?
      return unless existing_pipeline.merge_request_diff_sha == merge_request.diff_head_sha

      if existing_pipeline.running? || existing_pipeline.pending?
        cannot_create_pipeline_error('duplicate pipeline still in progress', retriable: true)
      else
        cannot_create_pipeline_error('duplicate pipeline')
      end
    end

    def cannot_create_pipeline_error(reason, retriable: false)
      message = "Cannot create a pipeline for this merge request: #{reason}."

      if retriable
        ServiceResponse.error(message: message, payload: nil, reason: :retriable_error)
      else
        ::Ci::PipelineCreation::Requests.failed(params[:pipeline_creation_request], message)
        ServiceResponse.error(message: message, payload: nil)
      end
    end
  end
end

MergeRequests::CreatePipelineService.prepend_mod_with('MergeRequests::CreatePipelineService')
