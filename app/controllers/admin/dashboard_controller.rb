class Admin::DashboardController < AdminController
  def index
    @workers = Resque.workers
    @pending_jobs = Resque.size(:post_receive)
    @projects = Project.order("created_at DESC").limit(10)
    @users = User.order("created_at DESC").limit(10)
  end
end
