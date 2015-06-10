# RootController
#
# This controller exists solely to handle requests to `root_url`. When a user is
# logged in and has customized their `dashboard` setting, they will be
# redirected to their preferred location.
#
# For users who haven't customized the setting, we simply delegate to
# `DashboardController#show`, which is the default.
class RootController < DashboardController
  def show
    case current_user.try(:dashboard)
    when 'stars'
      redirect_to starred_dashboard_projects_path
    else
      super
    end
  end
end
