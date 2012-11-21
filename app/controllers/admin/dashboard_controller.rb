class Admin::DashboardController < AdminController
  def index
    @projects = Project.order("created_at DESC").limit(10)
    @users = User.order("created_at DESC").limit(10)

    @resque_accessible = true
    @workers = Resque.workers
    @pending_jobs = Resque.size(:post_receive)

  rescue Redis::InheritedError
    @resque_accessible = false
  end
end
