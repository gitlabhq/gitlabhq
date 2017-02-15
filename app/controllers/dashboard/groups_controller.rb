class Dashboard::GroupsController < Dashboard::ApplicationController
  def index
    @group_members = current_user.group_members.includes(source: :route).page(params[:page])
  end
end
