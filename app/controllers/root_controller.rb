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

  def index
    # n+1: https://gitlab.com/gitlab-org/gitlab-ce/issues/37434
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      super
    end
  end

  private

  def redirect_unlogged_user
    if redirect_to_home_page_url?
      redirect_to(Gitlab::CurrentSettings.home_page_url)
    else
      redirect_to(new_user_session_path)
    end
  end

  def redirect_logged_user
    case current_user.dashboard
    when 'stars'
      flash.keep
      redirect_to(starred_dashboard_projects_path)
    when 'project_activity'
      redirect_to(activity_dashboard_path)
    when 'starred_project_activity'
      redirect_to(activity_dashboard_path(filter: 'starred'))
    when 'groups'
      redirect_to(dashboard_groups_path)
    when 'todos'
      redirect_to(dashboard_todos_path)
    when 'issues'
      redirect_to(issues_dashboard_path(assignee_id: current_user.id))
    when 'merge_requests'
      redirect_to(merge_requests_dashboard_path(assignee_id: current_user.id))
    end
  end

  def redirect_to_home_page_url?
    # If user is not signed-in and tries to access root_path - redirect him to landing page
    # Don't redirect to the default URL to prevent endless redirections
    return false unless Gitlab::CurrentSettings.home_page_url.present?

    home_page_url = Gitlab::CurrentSettings.home_page_url.chomp('/')
    root_urls = [Gitlab.config.gitlab['url'].chomp('/'), root_url.chomp('/')]

    root_urls.exclude?(home_page_url)
  end
end
