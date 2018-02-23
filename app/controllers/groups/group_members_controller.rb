class Groups::GroupMembersController < Groups::ApplicationController
  prepend EE::Groups::GroupMembersController

  include MembershipActions
  include MembersPresentation
  include SortingHelper

  # Authorize
  before_action :authorize_admin_group_member!, except: [:index, :leave, :request_access, :update, :override]
  before_action :authorize_update_group_member!, only: [:update, :override]

  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  def index
    @sort = params[:sort].presence || sort_value_name
    @project = @group.projects.find(params[:project_id]) if params[:project_id]

    @members = GroupMembersFinder.new(@group).execute
    @members = @members.non_invite unless can?(current_user, :admin_group, @group)
    @members = @members.search(params[:search]) if params[:search].present?
    @members = @members.sort(@sort)
    @members = @members.page(params[:page]).per(50)
    @members = present_members(@members.includes(:user))

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))

    @group_member = @group.group_members.new
  end

  def update
    @group_member = @group.members_and_requesters.find(params[:id])
      .present(current_user: current_user)

    return render_403 unless can?(current_user, :update_group_member, @group_member)

    old_access_level = @group_member.human_access

    if @group_member.update_attributes(member_params)
      log_audit_event(@group_member, action: :update, old_access_level: old_access_level)
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
