class UsersController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])

    unless current_user || @user.public_profile?
      return authenticate_user!
    end

    # Projects user can view
    authorized_projects_ids = ProjectsFinder.new.execute(current_user).pluck(:id)

    @projects = @user.personal_projects.
      where(id: authorized_projects_ids)

    # Collect only groups common for both users
    @groups = @user.groups & GroupsFinder.new.execute(current_user)

    # Get user activity feed for projects common for both users
    @events = @user.recent_events.
      where(project_id: authorized_projects_ids).limit(20)

    @title = @user.name
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
