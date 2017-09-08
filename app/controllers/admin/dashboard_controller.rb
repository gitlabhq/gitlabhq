class Admin::DashboardController < Admin::ApplicationController
  def index
<<<<<<< HEAD
    @projects = Project.without_deleted.with_route.limit(10)
    @users = User.limit(10)
    @groups = Group.with_route.limit(10)
    @license = License.current
=======
    @projects = Project.order_id_desc.without_deleted.with_route.limit(10)
    @users = User.order_id_desc.limit(10)
    @groups = Group.order_id_desc.with_route.limit(10)
>>>>>>> upstream/master
  end
end
