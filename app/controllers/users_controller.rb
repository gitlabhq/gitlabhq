class UsersController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :set_user
  layout :determine_layout

  def show
    @contributed_projects = Project.
      where(id: authorized_projects_ids & @user.contributed_projects_ids).
      in_group_namespace.
      includes(:namespace).
      reject(&:forked?)

    @projects = @user.personal_projects.
      where(id: authorized_projects_ids).includes(:namespace)

    # Collect only groups common for both users
    @groups = @user.groups & GroupsFinder.new.execute(current_user)

    # Get user activity feed for projects common for both users
    @events = @user.recent_events.
      where(project_id: authorized_projects_ids).
      with_associations.limit(30)

    @title = @user.name
    @title_url = user_path(@user)

    respond_to do |format|
      format.html
      format.atom { render layout: false }
    end
  end

  def calendar
    projects = Project.where(id: authorized_projects_ids & @user.contributed_projects_ids)

    calendar = Gitlab::CommitsCalendar.new(projects, @user)
    @timestamps = calendar.timestamps
    @starting_year = calendar.starting_year
    @starting_month = calendar.starting_month

    render 'calendar', layout: false
  end

  def calendar_activities
    projects = Project.where(id: authorized_projects_ids & @user.contributed_projects_ids)

    date = Date.parse(params[:date]) rescue nil
    if date
      @calendar_activities = Gitlab::CommitsCalendar.get_commits_for_date(projects, @user, date)
    else
      @calendar_activities = {}
    end

    # get the total number of unique commits
    @commit_count = @calendar_activities.values.flatten.map(&:id).uniq.count

    @calendar_date = date

    render 'calendar_activities', layout: false
  end

  def determine_layout
    if current_user
      'navless'
    else
      'public_users'
    end
  end

  private

  def set_user
    @user = User.find_by_username!(params[:username])

    unless current_user || @user.public_profile?
      return authenticate_user!
    end
  end

  def authorized_projects_ids
    # Projects user can view
    @authorized_projects_ids ||=
      ProjectsFinder.new.execute(current_user).pluck(:id)
  end
end
