class Admin::DashboardController < Admin::ApplicationController
  def index
    @projects = Project.with_route.limit(10)
    @users = User.limit(10)
<<<<<<< HEAD
    @groups = Group.limit(10)
    @license = License.current
=======
    @groups = Group.with_route.limit(10)
>>>>>>> ce/master
  end
end
