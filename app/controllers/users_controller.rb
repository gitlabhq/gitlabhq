class UsersController < ApplicationController
  layout 'navless'

  def show
    @user = User.find_by_username!(params[:username])
    @projects = @user.authorized_projects.where(id: current_user.authorized_projects.pluck(:id)).includes(:namespace)
    @events = @user.recent_events.where(project_id: @projects.map(&:id)).limit(20)

    @title = @user.name
  end
end
