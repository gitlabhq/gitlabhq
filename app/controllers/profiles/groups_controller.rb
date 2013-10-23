class Profiles::GroupsController < ApplicationController
  layout "profile"

  def index
    @user_groups = current_user.users_groups.page(params[:page]).per(20)
  end

  def leave
    @users_group = group.users_groups.where(user_id: current_user.id).first

    if group.last_owner?(current_user)
      redirect_to(profile_groups_path, alert: "You can't leave group. You must add at least one more owner to it.")
    else
      @users_group.destroy
      redirect_to(profile_groups_path, info: "You left #{group.name} group.")
    end
  end

  private

  def group
    @group ||= Group.find_by_path(params[:id])
  end
end
