class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = Project.without_pending_delete.limit(10)
    @users = User.limit(10)
    @groups = Group.limit(10)
  end
end
