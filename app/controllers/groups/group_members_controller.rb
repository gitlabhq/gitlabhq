class Groups::GroupMembersController < Groups::ApplicationController
  # Authorize
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

    redirect_to group_group_members_path(@group), notice: '用户增加成功。'
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
      format.html { redirect_to group_group_members_path(@group), notice: '用户从群组删除成功。' }
      format.js { head :ok }
    end
  end

  def resend_invite
    redirect_path = group_group_members_path(@group)

    @group_member = @group.group_members.find(params[:id])

    if @group_member.invite?
      @group_member.resend_invite

      redirect_to redirect_path, notice: '邀请重发成功。'
    else
      redirect_to redirect_path, alert: '邀请已经被接受。'
    end
  end

  def leave
    @group_member = @group.group_members.find_by(user_id: current_user)

    if can?(current_user, :destroy_group_member, @group_member)
      @group_member.destroy

      redirect_to(dashboard_groups_path, notice: "已离开 #{group.name} 群组。")
    else
      if @group.last_owner?(current_user)
        redirect_to(dashboard_groups_path, alert: "不能离开 #{group.name} 群组，因为你是最后一个群组所有者。请转移或删除群组。")
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
