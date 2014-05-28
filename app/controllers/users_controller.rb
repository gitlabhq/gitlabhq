class UsersController < ApplicationController
  include UsersHelper
  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.accessible_to(current_user)

    if !current_user && @projects.empty?
      return authenticate_user!
    end

    @groups = @user.groups.accessible_to(current_user)
    @events = @user.recent_events.where(project_id: @projects.pluck(:id)).limit(20)
    @title = @user.name

    user_projects = @user.authorized_projects.accessible_to(@user)
    @user_projects = user_projects.map(&:repository)
  end

  def activities
    @user = User.find_by_username!(params[:username])
    user_projects = @user.authorized_projects.accessible_to(@user)
    @user_project = user_projects.map(&:repository)

    user_activities = create_timestamps_by_project(@user_project)
    user_activities = commit_activity_match(user_activities)
    user_activities = user_activities.to_json
    render json: user_activities
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
