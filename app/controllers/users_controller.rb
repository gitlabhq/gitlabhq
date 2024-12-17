# frozen_string_literal: true

class UsersController < ApplicationController
  include InternalRedirect
  include RoutableActions
  include RendersMemberAccess
  include RendersProjectsList
  include ControllerWithCrossProjectAccessCheck
  include Gitlab::NoteableMetadata

  FOLLOWERS_FOLLOWING_USERS_PER_PAGE = 21

  requires_cross_project_access show: false,
    groups: false,
    projects: false,
    contributed: false,
    snippets: true,
    calendar: false,
    followers: false,
    following: false,
    calendar_activities: true

  skip_before_action :authenticate_user!
  prepend_before_action(only: [:show]) { authenticate_sessionless_user!(:rss) }
  before_action :user, except: [:exists]
  before_action :set_legacy_data
  before_action :authorize_read_user_profile!, only: [
    :calendar, :calendar_activities, :groups, :projects, :contributed, :starred, :snippets, :followers, :following
  ]
  before_action only: [:exists] do
    check_rate_limit!(:username_exists, scope: request.ip)
  end
  before_action only: [
    :show,
    :activity,
    :groups,
    :projects,
    :contributed,
    :starred,
    :snippets,
    :followers,
    :following
  ] do
    push_frontend_feature_flag(:profile_tabs_vue, current_user)
  end

  feature_category :user_profile, [:show, :activity, :groups, :projects, :contributed, :starred,
    :followers, :following, :calendar, :calendar_activities,
    :exists, :activity, :follow, :unfollow, :ssh_keys]

  feature_category :source_code_management, [:snippets, :gpg_keys]

  # TODO: Set higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/357914
  urgency :low, [:show, :calendar_activities, :contributed, :activity, :projects, :groups, :calendar, :snippets]
  urgency :default, [:followers, :following, :starred]
  urgency :high, [:exists]

  def show
    respond_to do |format|
      format.html

      format.atom do
        load_events
        render layout: 'xml'
      end

      format.json do
        msg = "This endpoint is deprecated. Use %s instead." % user_activity_path
        render json: { message: msg }, status: :not_found
      end
    end
  end

  # Get all keys of a user(params[:username]) in a text format
  # Helpful for sysadmins to put in respective servers
  def ssh_keys
    keys = user.all_ssh_keys.join("\n")
    keys << "\n" unless keys.empty?
    render plain: keys
  end

  def activity
    respond_to do |format|
      format.html { render 'show' }

      format.json do
        load_events

        if Feature.enabled?(:profile_tabs_vue, current_user)
          @events = if user.include_private_contributions?
                      @events
                    else
                      @events.select { |event| event.visible_to_user?(current_user) }
                    end

          render json: ::Profile::EventSerializer.new(current_user: current_user, target_user: user)
                                                 .represent(@events)
        else
          pager_json("events/_events", @events.count, events: @events)
        end
      end
    end
  end

  # Get all gpg keys of a user(params[:username]) in a text format
  def gpg_keys
    keys = user.gpg_keys.filter_map { |gpg_key| gpg_key.key if gpg_key.verified? }.join("\n")
    keys << "\n" unless keys.empty?
    render plain: keys
  end

  def groups
    respond_to do |format|
      format.html { render 'show' }
      format.json do
        load_groups

        render json: {
          html: view_to_html_string("shared/groups/_list", groups: @groups)
        }
      end
    end
  end

  def projects
    present_projects do
      load_projects
    end
  end

  def contributed
    present_projects do
      load_contributed_projects
    end
  end

  def starred
    present_projects do
      load_starred_projects
    end
  end

  def followers
    present_users do
      @user_followers = user.followers.page(params[:page]).per(FOLLOWERS_FOLLOWING_USERS_PER_PAGE)
    end
  end

  def following
    present_users do
      @user_following = user.followees.page(params[:page]).per(FOLLOWERS_FOLLOWING_USERS_PER_PAGE)
    end
  end

  def present_projects
    skip_pagination = Gitlab::Utils.to_boolean(params[:skip_pagination])
    skip_namespace = Gitlab::Utils.to_boolean(params[:skip_namespace])
    compact_mode = Gitlab::Utils.to_boolean(params[:compact_mode])
    card_mode = Gitlab::Utils.to_boolean(params[:card_mode])

    respond_to do |format|
      format.html { render 'show' }
      format.json do
        projects = yield

        pager_json(
          "shared/projects/_list",
          projects.count,
          projects: projects,
          skip_pagination: skip_pagination,
          skip_namespace: skip_namespace,
          compact_mode: compact_mode,
          card_mode: card_mode
        )
      end
    end
  end

  def snippets
    respond_to do |format|
      format.html { render 'show' }
      format.json do
        load_snippets

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
    @calendar_date = begin
      Date.parse(params[:date])
    rescue StandardError
      Date.today
    end
    @events = contributions_calendar.events_by_date(@calendar_date).map(&:present)

    render 'calendar_activities', layout: false
  end

  def exists
    if Gitlab::CurrentSettings.signup_enabled? || current_user
      render json: { exists: Namespace.username_reserved?(params[:username]) }
    else
      render json: { error: _('You must be authenticated to access this path.') }, status: :unauthorized
    end
  end

  def follow
    followee = current_user.follow(user)

    if followee
      flash[:alert] = followee.errors.full_messages.join(', ') if followee&.errors&.any?
    else
      flash[:alert] = s_('Action not allowed.')
    end

    redirect_path = referer_path(request) || @user

    redirect_to redirect_path
  end

  def unfollow
    response = ::Users::UnfollowService.new(
      follower: current_user,
      followee: user
    ).execute

    flash[:alert] = response.message if response.error?
    redirect_path = referer_path(request) || @user

    redirect_to redirect_path
  end

  private

  def user
    @user ||= find_routable!(User, params[:username], request.fullpath)
  end

  def personal_projects
    PersonalProjectsFinder.new(user).execute(current_user)
  end

  def contributed_projects
    ContributedProjectsFinder.new(
      user: user, current_user: current_user, params: { sort: 'latest_activity_desc' }
    ).execute
  end

  def starred_projects
    StarredProjectsFinder.new(user, params: finder_params, current_user: current_user).execute
  end

  def contributions_calendar
    @contributions_calendar ||= Gitlab::ContributionsCalendar.new(user, current_user)
  end

  def load_events
    @events = UserRecentEventsFinder.new(current_user, user, nil, params).execute

    Events::RenderService.new(current_user).execute(@events, atom_request: request.format.atom?)
  end

  def load_projects
    @projects = personal_projects
      .page(params[:page])
      .per(params[:limit])

    prepare_projects_for_rendering(@projects)
  end

  def load_contributed_projects
    @contributed_projects = contributed_projects.with_route.joined(user).page(params[:page]).without_count

    prepare_projects_for_rendering(@contributed_projects)
  end

  def load_starred_projects
    @starred_projects = starred_projects

    prepare_projects_for_rendering(@starred_projects)
  end

  def load_groups
    groups = JoinedGroupsFinder.new(user).execute(current_user)
    @groups = groups.page(params[:page]).without_count

    prepare_groups_for_rendering(@groups)
  end

  def load_snippets
    @snippets = SnippetsFinder.new(current_user, author: user, scope: params[:scope])
      .execute
      .page(params[:page])
      .inc_author

    @noteable_meta_data = noteable_meta_data(@snippets, 'Snippet')
  end

  def build_canonical_path(user)
    url_for(safe_params.merge(username: user.to_param))
  end

  def authorize_read_user_profile!
    access_denied! unless can?(current_user, :read_user_profile, user)
  end

  def present_users
    respond_to do |format|
      format.html { render 'show' }
      format.json do
        users = yield
        render json: {
          html: view_to_html_string("shared/users/index", users: users)
        }
      end
    end
  end

  def finder_params
    {
      # don't display projects marked for deletion
      not_aimed_for_deletion: true
    }
  end

  def set_legacy_data
    controller_action = params[:action]
    @action = controller_action.gsub('show', 'overview')
    @endpoint = request.path
  end
end

UsersController.prepend_mod_with('UsersController')
