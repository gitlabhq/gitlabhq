class UsersController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show, :activities]
  layout :determine_layout

  def show
    @user = User.find_by_username!(params[:username])

    unless current_user || @user.public_profile?
      return authenticate_user!
    end

    # Projects user can view
    visible_projects = ProjectsFinder.new.execute(current_user)
    authorized_projects_ids = visible_projects.pluck(:id)

    @projects = @user.personal_projects.
      where(id: authorized_projects_ids)

    # Collect only groups common for both users
    @groups = @user.groups & GroupsFinder.new.execute(current_user)

    # Get user activity feed for projects common for both users
    @events = @user.recent_events.
      where(project_id: authorized_projects_ids).limit(30)

    @title = @user.name

    # Get user repositories and collect timestamps for commits
    user_repositories = visible_projects.map(&:repository)
    calendar = Gitlab::CommitsCalendar.new(user_repositories, @user)
    @timestamps = calendar.timestamps
    @starting_year = (Time.now - 1.year).strftime("%Y")
    @starting_month = Date.today.strftime("%m").to_i

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
