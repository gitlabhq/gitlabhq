class Groups::GroupMembersController < Groups::ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  # Authorize
  before_action :authorize_read_group!
  before_action :authorize_admin_group_member!, except: [:index, :leave]

  def index
    @project = @group.projects.find(params[:project_id]) if params[:project_id]
    @members = @group.group_members
    @members = @members.non_invite unless can?(current_user, :admin_group, @group)

    if params[:search].present?
      users = @group.users.search(params[:search]).to_a
      @members = @members.where(user_id: users)
    end

    @members = @members.order('access_level DESC').page(params[:page]).per(50)

    @group_member = @group.group_members.new
  end

  def create
    @group.add_users(params[:user_ids].split(','), params[:access_level], current_user)

    redirect_to group_group_members_path(@group), notice: 'Users were successfully added.'
  end

  def update
    @group_member = @group.group_members.find(params[:id])

    return render_403 unless can?(current_user, :update_group_member, @group_member)

    @group_member.update_attributes(member_params)
  end

  def destroy
    @group_member = @group.group_members.find(params[:id])

    return render_403 unless can?(current_user, :destroy_group_member, @group_member)

    @group_member.destroy

    respond_to do |format|
      format.html { redirect_to group_group_members_path(@group), notice: 'User was successfully removed from group.' }
      format.js { render nothing: true }
    end
  end

  def resend_invite
    redirect_path = group_group_members_path(@group)

    @group_member = @group.group_members.find(params[:id])

    if @group_member.invite?
      @group_member.resend_invite

      redirect_to redirect_path, notice: 'The invitation was successfully resent.'
    else
      redirect_to redirect_path, alert: 'The invitation has already been accepted.'
    end
  end

  def leave
    @group_member = @group.group_members.find_by(user_id: current_user)

    if can?(current_user, :destroy_group_member, @group_member)
      @group_member.destroy

      redirect_to(dashboard_groups_path, notice: "You left #{group.name} group.")
    else
      if @group.last_owner?(current_user)
        redirect_to(dashboard_groups_path, alert: "You can not leave #{group.name} group because you're the last owner. Transfer or delete the group.")
      else
        return render_403
      end
    end
  end

  protected

  def member_params
    params.require(:group_member).permit(:access_level, :user_id)
  end
end
