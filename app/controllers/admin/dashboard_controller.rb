class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = Project.limit(10)
    @users = User.limit(10)
    @groups = Group.limit(10)
    @license = License.current
  end
end
