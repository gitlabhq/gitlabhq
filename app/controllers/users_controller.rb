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

    user_repositories = visible_projects.map(&:repository)
    @timestamps = Gitlab::CommitsCalendar.create_timestamp(user_repositories,
                                                           @user, false)
    @starting_year = (Time.now - 1.year).strftime("%Y")
    @starting_month = Date.today.strftime("%m").to_i
    @last_commit_date = Gitlab::CommitsCalendar.last_commit_date(@timestamps)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def activities
    user = User.find_by_username!(params[:username])
    # Projects user can view
    visible_projects = ProjectsFinder.new.execute(current_user)

    user_repositories = visible_projects.map(&:repository)
    user_activities = Gitlab::CommitsCalendar.create_timestamp(user_repositories,
                                                               user, true)
    user_activities = Gitlab::CommitsCalendar.commit_activity_match(
                                              user_activities, params[:date])
    render json: user_activities.to_json
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end
end
