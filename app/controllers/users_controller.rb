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

    user_projects = @user.authorized_projects.accessible_to(@user)
    @user_projects = user_projects.map(&:repository)

    @timestamps = Gitlab::CommitsCalendar.create_timestamp(@user_projects,
                                                           @user, false)
    @starting_year = Gitlab::CommitsCalendar.starting_year(@timestamps)
    @starting_month = Gitlab::CommitsCalendar.starting_month(@timestamps)
    @last_commit_date = Gitlab::CommitsCalendar.last_commit_date(@timestamps)
  end

  def activities
    @user = User.find_by_username!(params[:username])
    user_projects = @user.authorized_projects.accessible_to(@user)
    @user_projects = user_projects.map(&:repository)

    user_activities = Gitlab::CommitsCalendar.create_timestamp(@user_projects,
                                                               @user, true)
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
