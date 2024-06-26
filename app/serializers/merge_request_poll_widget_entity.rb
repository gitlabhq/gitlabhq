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
  expose :ff_only_enabled do |merge_request|
    merge_request.project.merge_requests_ff_only_enabled
  end

  expose :ff_merge_possible?, as: :ff_merge_possible

  # User entities
  expose :merge_user, using: UserEntity

  expose :default_merge_commit_message do |merge_request, options|
    merge_request.default_merge_commit_message(include_description: false, user: current_user)
  end

  expose :mergeable do |merge_request, options|
    merge_request.mergeable?
  end

  expose :default_merge_commit_message_with_description do |merge_request|
    merge_request.default_merge_commit_message(include_description: true)
  end

  expose :only_allow_merge_if_pipeline_succeeds do |merge_request|
    merge_request.project.only_allow_merge_if_pipeline_succeeds?(inherit_group_setting: true)
  end

  # CI related
  expose :has_ci?, as: :has_ci
  expose :ci_status, if: ->(mr, _) { presenter(mr).can_read_pipeline? } do |merge_request|
    presenter(merge_request).ci_status
  end

  expose :pipeline_coverage_delta do |merge_request|
    presenter(merge_request).pipeline_coverage_delta
  end

  expose :head_pipeline_builds_with_coverage, as: :builds_with_coverage, using: BuildCoverageEntity

  expose :cancel_auto_merge_path do |merge_request|
    presenter(merge_request).cancel_auto_merge_path
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

  expose :squash_enabled_by_default do |merge_request|
    presenter(merge_request).project.squash_enabled_by_default?
  end

  expose :squash_readonly do |merge_request|
    presenter(merge_request).project.squash_readonly?
  end

  expose :squash_on_merge do |merge_request|
    presenter(merge_request).squash_on_merge?
  end

  expose :approvals_widget_type do |merge_request|
    presenter(merge_request).approvals_widget_type
  end

  expose :jenkins_integration_active do |merge_request|
    presenter(merge_request).jenkins_integration_active
  end

  expose :retargeted

  private

  delegate :current_user, to: :request

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: current_user) # rubocop: disable CodeReuse/Presenter
  end
end

MergeRequestPollWidgetEntity.prepend_mod_with('MergeRequestPollWidgetEntity')
