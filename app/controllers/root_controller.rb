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
  skip_before_action :authenticate_user!, only: [:index]

  before_action :redirect_unlogged_user, if: -> { current_user.nil? }
  before_action :redirect_logged_user, if: -> { current_user.present? }

  before_action only: [:index] do
    push_frontend_feature_flag(:personal_homepage, current_user)
  end

  CACHE_CONTROL_HEADER = 'no-store'

  def index
    render('root/index') && return if Feature.enabled?(:personal_homepage, current_user)

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
    case current_user.dashboard
    when 'projects'
      redirect_to(dashboard_projects_path) if Feature.enabled?(:personal_homepage, current_user)
    when 'stars'
      flash.keep
      redirect_to(starred_dashboard_projects_path)
    when 'member_projects'
      flash.keep
      redirect_to(member_dashboard_projects_path)
    when 'your_activity'
      redirect_to(activity_dashboard_path)
    when 'project_activity'
      redirect_to(activity_dashboard_path(filter: 'projects'))
    when 'starred_project_activity'
      redirect_to(activity_dashboard_path(filter: 'starred'))
    when 'followed_user_activity'
      redirect_to(activity_dashboard_path(filter: 'followed'))
    when 'groups'
      redirect_to(dashboard_groups_path)
    when 'todos'
      redirect_to(dashboard_todos_path)
    when 'issues'
      redirect_to(issues_dashboard_path(assignee_username: current_user.username))
    when 'merge_requests'
      redirect_to(merge_requests_dashboard_path(assignee_username: current_user.username))
    end
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
