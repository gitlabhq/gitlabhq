# frozen_string_literal: true

class AutocompleteController < ApplicationController
  skip_before_action :authenticate_user!, only: [:users, :award_emojis, :merge_request_target_branches]

  def users
    project = Autocomplete::ProjectFinder
      .new(current_user, params)
      .execute

    group = Autocomplete::GroupFinder
      .new(current_user, project, params)
      .execute

    users = Autocomplete::UsersFinder
      .new(params: params, current_user: current_user, project: project, group: group)
      .execute

    render json: UserSerializer.new(params).represent(users, project: project)
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

  private

  def target_branch_params
    params.permit(:group_id, :project_id)
  end
end

AutocompleteController.prepend_if_ee('EE::AutocompleteController')
