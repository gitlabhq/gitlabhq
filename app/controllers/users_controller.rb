class UsersController < ApplicationController

  skip_before_filter :authenticate_user!, only: [:show]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])
    if not can?(current_user, :read_user, @user)
      if current_user
        return render_404
      else
        return authenticate_user!
      end
    end
    @projects = (@user.authorized_projects.select {|project| can?(current_user, :read_project, project)})
    @events = @user.recent_events.where(project_id: @projects.map(&:id)).limit(20)
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
