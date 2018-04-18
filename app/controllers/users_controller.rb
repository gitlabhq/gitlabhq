class UsersController < ApplicationController
  include RoutableActions
  include RendersMemberAccess
  include ControllerWithCrossProjectAccessCheck

  requires_cross_project_access show: false,
                                groups: false,
                                projects: false,
                                contributed: false,
                                snippets: true,
                                calendar: false,
                                calendar_activities: true

  skip_before_action :authenticate_user!
  before_action :user, except: [:exists]

  def show
    respond_to do |format|
      format.html

      format.atom do
        load_events
        render layout: 'xml.atom'
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
          html: view_to_html_string("shared/projects/_list", projects: @projects)
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
        render json: {
          html: view_to_html_string("snippets/_snippets", collection: @snippets)
        }
      end
    end
  end

  def calendar
    render json: contributions_calendar.activity_dates
  end

  def calendar_activities
    @calendar_date = Date.parse(params[:date]) rescue Date.today
    @events = contributions_calendar.events_by_date(@calendar_date)

    render 'calendar_activities', layout: false
  end

  def exists
    render json: { exists: !!Namespace.find_by_path_or_name(params[:username]) }
  end

  private

  def user
    @user ||= find_routable!(User, params[:username])
  end

  def contributed_projects
    ContributedProjectsFinder.new(user).execute(current_user)
  end

  def contributions_calendar
    @contributions_calendar ||= Gitlab::ContributionsCalendar.new(user, current_user)
  end

  def load_events
    @events = UserRecentEventsFinder.new(current_user, user, params).execute

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def load_projects
    @projects =
      PersonalProjectsFinder.new(user).execute(current_user)
      .page(params[:page])

    prepare_projects_for_rendering(@projects)
  end

  def load_contributed_projects
    @contributed_projects = contributed_projects.joined(user)

    prepare_projects_for_rendering(@contributed_projects)
  end

  def load_groups
    @groups = JoinedGroupsFinder.new(user).execute(current_user)

    prepare_groups_for_rendering(@groups)
  end

  def load_snippets
    @snippets = SnippetsFinder.new(
      current_user,
      author: user,
      scope: params[:scope]
    ).execute.page(params[:page])
  end

  def build_canonical_path(user)
    url_for(safe_params.merge(username: user.to_param))
  end
end
