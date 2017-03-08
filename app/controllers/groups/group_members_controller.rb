class Groups::GroupMembersController < Groups::ApplicationController
  prepend EE::Groups::GroupMembersController

  include MembershipActions
  include SortingHelper

  # Authorize
  before_action :authorize_admin_group_member!, except: [:index, :leave, :request_access, :update, :override]
  before_action :authorize_update_group_member!, only: [:update, :override]

  def index
    @sort = params[:sort].presence || sort_value_name
    @project = @group.projects.find(params[:project_id]) if params[:project_id]

    @members = GroupMembersFinder.new(@group).execute
    @members = @members.non_invite unless can?(current_user, :admin_group, @group)
    @members = @members.search(params[:search]) if params[:search].present?
    @members = @members.sort(@sort)
    @members = @members.page(params[:page]).per(50)

    @requesters = AccessRequestsFinder.new(@group).execute(current_user)

    @group_member = @group.group_members.new
  end

  def create
    if params[:user_ids].blank?
      return redirect_to(group_group_members_path(@group), alert: 'No users specified.')
    end

    @group.add_users(
      params[:user_ids].split(','),
      params[:access_level],
      current_user: current_user,
      expires_at: params[:expires_at]
    )

    group_members = @group.group_members.where(user_id: params[:user_ids].split(','))

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
    member = Members::DestroyService.new(@group, current_user, id: params[:id]).execute(:all)

    log_audit_event(member, action: :destroy)

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
    params.require(:group_member).permit(:access_level, :user_id, :expires_at)
  end

  # MembershipActions concern
  alias_method :membershipable, :group
end
