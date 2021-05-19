# frozen_string_literal: true

class AutocompleteController < ApplicationController
  skip_before_action :authenticate_user!, only: [:users, :award_emojis, :merge_request_target_branches]

  feature_category :users, [:users, :user]
  feature_category :projects, [:projects]
  feature_category :issue_tracking, [:award_emojis]
  feature_category :code_review, [:merge_request_target_branches]
  feature_category :continuous_delivery, [:deploy_keys_with_owners]

  def users
    group = Autocomplete::GroupFinder
      .new(current_user, project, params)
      .execute

    users = Autocomplete::UsersFinder
      .new(params: params, current_user: current_user, project: project, group: group)
      .execute

    render json: UserSerializer.new(params.merge({ current_user: current_user })).represent(users, project: project)
  end

  def user
    user = UserFinder.new(params[:id]).find_by_id!

    render json: UserSerializer.new.represent(user)
  end

  # Displays projects to use for the dropdown when moving a resource from one
  # project to another.
  def projects
    projects = Autocomplete::MoveToProjectFinder
      .new(current_user, params)
      .execute

    render json: MoveToProjectSerializer.new.represent(projects)
  end

  def award_emojis
    render json: AwardEmojis::CollectUserEmojiService.new(current_user).execute
  end

  def merge_request_target_branches
    if target_branch_params.present?
      merge_requests = MergeRequestsFinder.new(current_user, target_branch_params).execute
      target_branches = merge_requests.recent_target_branches

      render json: target_branches.map { |target_branch| { title: target_branch } }
    else
      render json: { error: _('At least one of group_id or project_id must be specified') }, status: :bad_request
    end
  end

  def deploy_keys_with_owners
    deploy_keys = DeployKey.with_write_access_for_project(project)

    render json: DeployKeySerializer.new.represent(deploy_keys, { with_owner: true, user: current_user })
  end

  private

  def project
    @project ||= Autocomplete::ProjectFinder
      .new(current_user, params)
      .execute
  end

  def target_branch_params
    params.permit(:group_id, :project_id).select { |_, v| v.present? }
  end
end

AutocompleteController.prepend_mod_with('AutocompleteController')
