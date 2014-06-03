class UsersController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])
    @projects = Project.personal(@user).accessible_to(current_user)

    unless current_user || @user.public_profile?
      return authenticate_user!
    end

    @groups = @user.groups.accessible_to(current_user)
    accessible_projects = @user.authorized_projects.accessible_to(current_user)
    @events = @user.recent_events.where(project_id: accessible_projects.pluck(:id)).limit(20)
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
