class Admin::DashboardController < Admin::ApplicationController
  prepend ::EE::Admin::DashboardController

  include CountHelper

  def index
    @projects = Project.order_id_desc.without_deleted.with_route.limit(10)
    @users = User.order_id_desc.limit(10)
    @groups = Group.order_id_desc.with_route.limit(10)
    @license = License.current
  end
end
