# frozen_string_literal: true

class MergeRequestPollWidgetEntity < Grape::Entity
  include RequestAwareEntity

  expose :auto_merge_strategy
  expose :available_auto_merge_strategies do |merge_request|
    AutoMergeService.new(merge_request.project, current_user).available_strategies(merge_request) # rubocop: disable CodeReuse/ServiceClass
  end
  expose :source_branch_protected do |merge_request|
    merge_request.source_project.present? && ProtectedBranch.protected?(merge_request.source_project, merge_request.source_branch)
  end
  expose :allow_collaboration
  expose :should_be_rebased?, as: :should_be_rebased
  expose :ff_only_enabled do |merge_request|
    merge_request.project.merge_requests_ff_only_enabled
  end

  # User entities
  expose :merge_user, using: UserEntity

  expose :actual_head_pipeline, with: PipelineDetailsEntity, as: :pipeline, if: -> (mr, _) { presenter(mr).can_read_pipeline? }

  expose :merge_pipeline, with: PipelineDetailsEntity, if: ->(mr, _) { mr.merged? && can?(request.current_user, :read_pipeline, mr.target_project)}

  expose :default_merge_commit_message

  expose :mergeable?, as: :mergeable

  expose :default_merge_commit_message_with_description do |merge_request|
    merge_request.default_merge_commit_message(include_description: true)
  end

  # Booleans
  expose :mergeable_discussions_state?, as: :mergeable_discussions_state do |merge_request|
    # This avoids calling MergeRequest#mergeable_discussions_state without
    # considering the state of the MR first. If a MR isn't mergeable, we can
    # safely short-circuit it.
    if merge_request.mergeable_state?(skip_ci_check: true, skip_discussions_check: true)
      merge_request.mergeable_discussions_state?
    else
      false
    end
  end

  expose :project_archived do |merge_request|
    merge_request.project.archived?
  end

  expose :only_allow_merge_if_pipeline_succeeds do |merge_request|
    merge_request.project.only_allow_merge_if_pipeline_succeeds?
  end

  # CI related
  expose :has_ci?, as: :has_ci
  expose :ci_status do |merge_request|
    presenter(merge_request).ci_status
  end

  expose :cancel_auto_merge_path do |merge_request|
    presenter(merge_request).cancel_auto_merge_path
  end

  expose :test_reports_path do |merge_request|
    if merge_request.has_test_reports?
      test_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :exposed_artifacts_path do |merge_request|
    if merge_request.has_exposed_artifacts?
      exposed_artifacts_project_merge_request_path(merge_request.project, merge_request, format: :json)
    end
  end

  expose :create_issue_to_resolve_discussions_path do |merge_request|
    presenter(merge_request).create_issue_to_resolve_discussions_path
  end

  expose :current_user do
    expose :can_remove_source_branch do |merge_request|
      presenter(merge_request).can_remove_source_branch?
    end

    expose :can_revert_on_current_merge_request do |merge_request|
      presenter(merge_request).can_revert_on_current_merge_request?
    end

    expose :can_cherry_pick_on_current_merge_request do |merge_request|
      presenter(merge_request).can_cherry_pick_on_current_merge_request?
    end

    expose :can_create_issue do |merge_request|
      can?(current_user, :create_issue, merge_request.project)
    end
  end

  expose :can_push_to_source_branch do |merge_request|
    presenter(merge_request).can_push_to_source_branch?
  end

  expose :new_blob_path do |merge_request|
    if presenter(merge_request).can_push_to_source_branch?
      project_new_blob_path(merge_request.source_project, merge_request.source_branch)
    end
  end

  expose :rebase_path do |merge_request|
    presenter(merge_request).rebase_path
  end

  expose :conflict_resolution_path do |merge_request|
    presenter(merge_request).conflict_resolution_path
  end

  expose :remove_wip_path do |merge_request|
    presenter(merge_request).remove_wip_path
  end

  expose :merge_path do |merge_request|
    presenter(merge_request).merge_path
  end

  expose :cherry_pick_in_fork_path do |merge_request|
    presenter(merge_request).cherry_pick_in_fork_path
  end

  expose :revert_in_fork_path do |merge_request|
    presenter(merge_request).revert_in_fork_path
  end

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end
end

MergeRequestPollWidgetEntity.prepend_if_ee('EE::MergeRequestPollWidgetEntity')
