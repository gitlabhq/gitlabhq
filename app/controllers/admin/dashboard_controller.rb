class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = Project.order("created_at DESC").limit(10)
    @users = User.order("created_at DESC").limit(10)

  rescue Redis::InheritedError
    @resque_accessible = false
  end
end
