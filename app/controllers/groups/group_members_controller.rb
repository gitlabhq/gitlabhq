class Groups::GroupMembersController < Groups::ApplicationController
  include MembershipActions

  # Authorize
  before_action :authorize_admin_group_member!, except: [:index, :leave, :request_access]

  def index
    @project = @group.projects.find(params[:project_id]) if params[:project_id]
    @members = @group.group_members
    @members = @members.non_invite unless can?(current_user, :admin_group, @group)

    if params[:search].present?
      users = @group.users.search(params[:search]).to_a
      @members = @members.where(user_id: users)
    end

    @members = @members.order('access_level DESC').page(params[:page]).per(50)
    @requesters = @group.requesters if can?(current_user, :admin_group, @group)

    @group_member = @group.group_members.new
  end

  def create
    access_level = params[:access_level]
    user_ids = params[:user_ids].split(',')

    @group.add_users(user_ids, access_level, current_user)
    group_members = @group.group_members.where(user_id: user_ids)

    group_members.each do |group_member|
      log_audit_event(group_member, action: :create)
    end

    redirect_to group_group_members_path(@group), notice: 'Users were successfully added.'
  end

  def update
    @group_member = @group.group_members.find(params[:id])

    return render_403 unless can?(current_user, :update_group_member, @group_member)

    old_access_level = @group_member.human_access

    if @group_member.update_attributes(member_params)
      log_audit_event(@group_member, action: :update, old_access_level: old_access_level)
    end
  end

  def destroy
    @group_member = @group.members.find_by(id: params[:id]) ||
      @group.requesters.find_by(id: params[:id])

    Members::DestroyService.new(@group_member, current_user).execute
    log_audit_event(@group_member, action: :destroy)

    respond_to do |format|
      format.html { redirect_to group_group_members_path(@group), notice: 'User was successfully removed from group.' }
      format.js { head :ok }
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

  protected

  def member_params
    params.require(:group_member).permit(:access_level, :user_id)
  end

  # MembershipActions concern
  alias_method :membershipable, :group
end
