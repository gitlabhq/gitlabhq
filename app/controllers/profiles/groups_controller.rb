class Profiles::GroupsController < ApplicationController
  layout "profile"

  def index
    @user_groups = current_user.users_groups.page(params[:page]).per(20)
  end

  def leave
    @users_group = group.users_groups.where(user_id: current_user.id).first
    if can?(current_user, :destroy, @users_group)
      @users_group.destroy
      redirect_to(profile_groups_path, info: "You left #{group.name} group.")
    else
      return render_403
    end
  end

  private

  def group
    @group ||= Group.find_by(path: params[:id])
  end
end
