class AutocompleteController < ApplicationController
  prepend EE::AutocompleteController

  skip_before_action :authenticate_user!, only: [:users, :award_emojis]

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

    render json: UserSerializer.new.represent(users)
  end

  def user
    user = UserFinder.new(params).execute!

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
    render json: AwardedEmojiFinder.new(current_user).execute
  end
end
