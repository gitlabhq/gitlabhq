class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = Project.without_deleted.with_route.limit(10)
    @users = User.limit(10)
    @groups = Group.with_route.limit(10)
    @license = License.current
  end
end
