class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = ProjectsFinder.execute(current_user, scope: all).limit(10)
    @users = User.limit(10)
    @groups = Group.limit(10)
  end
end
