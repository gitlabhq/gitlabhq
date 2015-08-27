class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_user

  def show
    @contributed_projects = contributed_projects.joined(@user).
      reject(&:forked?)

    @projects = @user.personal_projects.
      where(id: authorized_projects_ids).includes(:namespace)

    # Collect only groups common for both users
    @groups = @user.groups & GroupsFinder.new.execute(current_user)

    respond_to do |format|
      format.html

      format.atom do
        load_events
        render layout: false
      end

      format.json do
        load_events
        pager_json("events/_events", @events.count)
      end
    end
  end

  def calendar
    calendar = contributions_calendar
    @timestamps = calendar.timestamps
    @starting_year = calendar.starting_year
    @starting_month = calendar.starting_month

    render 'calendar', layout: false
  end

  def calendar_activities
    @calendar_date = Date.parse(params[:date]) rescue nil
    @events = []

    if @calendar_date
      @events = contributions_calendar.events_by_date(@calendar_date)
    end

    render 'calendar_activities', layout: false
  end

  private

  def set_user
    @user = User.find_by_username!(params[:username])
  end

  def authorized_projects_ids
    # Projects user can view
    @authorized_projects_ids ||=
      ProjectsFinder.new.execute(current_user).pluck(:id)
  end

  def contributed_projects
    @contributed_projects = Project.
      where(id: authorized_projects_ids & @user.contributed_projects_ids).
      includes(:namespace)
  end

  def contributions_calendar
    @contributions_calendar ||= Gitlab::ContributionsCalendar.
      new(contributed_projects.reject(&:forked?), @user)
  end

  def load_events
    # Get user activity feed for projects common for both users
    @events = @user.recent_events.
      where(project_id: authorized_projects_ids).
      with_associations

    @events = @events.limit(20).offset(params[:offset] || 0)
  end
end
