class UsersController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.includes(:namespace).select {|project| can?(current_user, :read_project, project)}
    if !current_user && @projects.empty?
      return authenticate_user!
    end
    @events = @user.recent_events.where(project_id: @projects.map(&:id)).limit(20)
    @title = @user.name
    @groups = @projects.map(&:group).compact.uniq
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
