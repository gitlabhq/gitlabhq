# frozen_string_literal: true

# RootController
#
# This controller exists solely to handle requests to `root_url`. When a user is
# logged in and has customized their `dashboard` setting, they will be
# redirected to their preferred location.
#
# For users who haven't customized the setting, we simply delegate to
# `DashboardController#show`, which is the default.
class RootController < Dashboard::ProjectsController
  include HomepageData
  include ::Gitlab::InternalEventsTracking

  skip_before_action :authenticate_user!, only: [:index]

  before_action :redirect_unlogged_user, if: -> { current_user.nil? }
  before_action :redirect_logged_user, if: -> { current_user.present? }

  before_action only: [:index] do
    push_frontend_feature_flag(:personal_homepage, current_user)
  end

  CACHE_CONTROL_HEADER = 'no-store'

  DASHBOARD_PATHS = {
    'projects' => ->(context) {
      context.dashboard_projects_path if Feature.enabled?(:personal_homepage, context.current_user)
    },
    'stars' => ->(context) { context.starred_dashboard_projects_path },
    'member_projects' => ->(context) { context.member_dashboard_projects_path },
    'your_activity' => ->(context) { context.activity_dashboard_path },
    'project_activity' => ->(context) { context.activity_dashboard_path(filter: 'projects') },
    'starred_project_activity' => ->(context) { context.activity_dashboard_path(filter: 'starred') },
    'followed_user_activity' => ->(context) { context.activity_dashboard_path(filter: 'followed') },
    'groups' => ->(context) { context.dashboard_groups_path },
    'todos' => ->(context) { context.dashboard_todos_path },
    'issues' => ->(context) { context.issues_dashboard_path(assignee_username: context.current_user.username) },
    'merge_requests' => ->(context) { context.merge_requests_dashboard_path },
    'assigned_merge_requests' => ->(context) {
      context.merge_requests_search_dashboard_path(assignee_username: context.current_user.username)
    },
    'review_merge_requests' => ->(context) {
      context.merge_requests_search_dashboard_path(reviewer_username: context.current_user.username)
    }
  }.freeze

  def index
    @homepage_app_data = homepage_app_data(current_user)
    if Feature.enabled?(:personal_homepage, current_user)
      track_internal_event('user_views_homepage', user: current_user)
      render('root/index') && return
    end

    super
  end

  private

  def redirect_unlogged_user
    redirect_path = redirect_to_home_page_url? ? Gitlab::CurrentSettings.home_page_url : new_user_session_path
    status = root_redirect_enabled? ? :moved_permanently : :found

    response.headers['Cache-Control'] = CACHE_CONTROL_HEADER if root_redirect_enabled?
    redirect_to(redirect_path, status: status)
  end

  def root_redirect_enabled?
    Gitlab::CurrentSettings.current_application_settings.root_moved_permanently_redirection
  end

  def redirect_logged_user
    dashboard_for_routing = current_user.effective_dashboard_for_routing

    redirect_path = dashboard_redirect_path(dashboard_for_routing)

    flash.keep if %w[stars member_projects].include?(dashboard_for_routing)

    redirect_to(redirect_path) if redirect_path
  end

  def dashboard_redirect_path(dashboard_type)
    DASHBOARD_PATHS[dashboard_type]&.call(self)
  end

  def redirect_to_home_page_url?
    # If user is not signed-in and tries to access root_path - redirect them to landing page
    # Don't redirect to the default URL to prevent endless redirections
    return false unless Gitlab::CurrentSettings.home_page_url.present?

    home_page_url = Gitlab::CurrentSettings.home_page_url.chomp('/')
    root_urls = [Gitlab.config.gitlab['url'].chomp('/'), root_url.chomp('/')]

    root_urls.exclude?(home_page_url)
  end
end

RootController.prepend_mod_with('RootController')
