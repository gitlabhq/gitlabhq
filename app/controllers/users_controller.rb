class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :user, except: [:exists]
  before_action :authorize_read_user!, only: [:show]

  def show
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

  def groups
    load_groups

    respond_to do |format|
      format.html { render 'show' }
      format.json do
        render json: {
          html: view_to_html_string("shared/groups/_list", groups: @groups)
        }
      end
    end
  end

  def projects
    load_projects

    respond_to do |format|
      format.html { render 'show' }
      format.json do
        render json: {
          html: view_to_html_string("shared/projects/_list", projects: @projects, remote: true)
        }
      end
    end
  end

  def contributed
    load_contributed_projects

    respond_to do |format|
      format.html { render 'show' }
      format.json do
        render json: {
          html: view_to_html_string("shared/projects/_list", projects: @contributed_projects)
        }
      end
    end
  end

  def snippets
    load_snippets

    respond_to do |format|
      format.html { render 'show' }
      format.json do
        render json: { html: @snippets.blank? ? nil : view_to_html_string("snippets/_snippets", collection: @snippets, remote: true) }
      end
    end
  end

  def calendar
    calendar = contributions_calendar
    @activity_dates = calendar.activity_dates

    render 'calendar', layout: false
  end

  def calendar_activities
    @calendar_date = Date.parse(params[:date]) rescue Date.today
    @events = contributions_calendar.events_by_date(@calendar_date)

    render 'calendar_activities', layout: false
  end

  def exists
    render json: { exists: Namespace.where(path: params[:username].downcase).any? }
  end

  private

  def authorize_read_user!
    render_404 unless can?(current_user, :read_user, user)
  end

  def user
    @user ||= User.find_by_username!(params[:username])
  end

  def contributed_projects
    ContributedProjectsFinder.new(user).execute(current_user)
  end

  def contributions_calendar
    @contributions_calendar ||= Gitlab::ContributionsCalendar.
      new(contributed_projects, user)
  end

  def load_events
    # Get user activity feed for projects common for both users
    @events = user.recent_events.
      merge(projects_for_current_user).
      references(:project).
      with_associations.
      limit_recent(20, params[:offset])
  end

  def load_projects
    @projects =
      PersonalProjectsFinder.new(user).execute(current_user)
      .page(params[:page])
  end

  def load_contributed_projects
    @contributed_projects = contributed_projects.joined(user)
  end

  def load_groups
    @groups = JoinedGroupsFinder.new(user).execute(current_user)
  end

  def load_snippets
    @snippets = SnippetsFinder.new.execute(
      current_user,
      filter: :by_user,
      user: user,
      scope: params[:scope]
    ).page(params[:page])
  end

  def projects_for_current_user
    ProjectsFinder.new.execute(current_user)
  end
end
