# frozen_string_literal: true

class AutocompleteController < ApplicationController
  include SearchRateLimitable

  skip_before_action :authenticate_user!, only: [
    :users, :award_emojis, :merge_request_target_branches, :merge_request_source_branches
  ]
  before_action :check_search_rate_limit!, only: [:users, :projects]

  feature_category :user_profile, [:users, :user]
  feature_category :groups_and_projects, [:projects]
  feature_category :team_planning, [:award_emojis]
  feature_category :code_review_workflow, [:merge_request_target_branches, :merge_request_source_branches]
  feature_category :continuous_delivery, [:deploy_keys_with_owners]

  urgency :low, [:merge_request_target_branches, :merge_request_source_branches, :deploy_keys_with_owners, :users]
  urgency :low, [:award_emojis]
  urgency :medium, [:projects]

  def users
    group = Autocomplete::GroupFinder
      .new(current_user, project, params)
      .execute

    users = Autocomplete::UsersFinder
      .new(params: params, current_user: current_user, project: project, group: group)
      .execute

    presented_users = UserSerializer
                        .new(params.merge({ current_user: current_user }))
                        .represent(users, project: project)

    extra_users = presented_suggested_users

    if extra_users.present?
      presented_users.reject! do |user|
        extra_users.any? { |suggested_user| suggested_user[:id] == user[:id] }
      end
      presented_users += extra_users
    end

    render json: presented_users
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
    merge_request_branches(target: true)
  end

  def merge_request_source_branches
    merge_request_branches(source: true)
  end

  def deploy_keys_with_owners
    deploy_keys = Autocomplete::DeployKeysWithWriteAccessFinder
      .new(current_user, project)
      .execute

    render json: DeployKeys::BasicDeployKeySerializer.new.represent(
      deploy_keys, { with_owner: true, user: current_user }
    )
  end

  private

  def project
    @project ||= Autocomplete::ProjectFinder
      .new(current_user, params)
      .execute
  end

  def branch_params
    params.permit(:group_id, :project_id).select { |_, v| v.present? }
  end

  # overridden in EE
  def presented_suggested_users
    []
  end

  def merge_request_branches(source: false, target: false)
    if branch_params.present?
      merge_requests = MergeRequestsFinder.new(current_user, branch_params).execute

      branches = []

      branches.concat(merge_requests.recent_source_branches) if source
      branches.concat(merge_requests.recent_target_branches) if target

      render json: branches.map { |branch| { title: branch } }
    else
      render json: { error: _('At least one of group_id or project_id must be specified') }, status: :bad_request
    end
  end
end

AutocompleteController.prepend_mod_with('AutocompleteController')
