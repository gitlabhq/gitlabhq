class Groups::GroupMembersController < ApplicationController
  before_filter :group

  # Authorize
  before_filter :authorize_admin_group!

  layout 'group'

  def create
    @group.add_users(params[:user_ids].split(','), params[:access_level])

    redirect_to members_group_path(@group), notice: 'Users were successfully added.'
  end

  def update
    @member = @group.group_members.find(params[:id])
    @member.update_attributes(member_params)
  end

  def destroy
    @users_group = @group.group_members.find(params[:id])

    if can?(current_user, :destroy, @users_group)  # May fail if last owner.
      @users_group.destroy
      respond_to do |format|
        format.html { redirect_to members_group_path(@group), notice: 'User was  successfully removed from group.' }
        format.js { render nothing: true }
      end
    else
      return render_403
    end
  end

  protected

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end

  def member_params
    params.require(:group_member).permit(:access_level, :user_id)
  end
end
