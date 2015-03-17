class Groups::GroupMembersController < Groups::ApplicationController
  skip_before_filter :authenticate_user!, only: [:index]
  before_filter :group

  # Authorize
  before_filter :authorize_read_group!
  before_filter :authorize_admin_group!, except: [:index, :leave]

  layout :determine_layout

  def index
    @project = @group.projects.find(params[:project_id]) if params[:project_id]
    @members = @group.group_members

    if params[:search].present?
      users = @group.users.search(params[:search]).to_a
      @members = @members.where(user_id: users)
    end

    @members = @members.order('access_level DESC').page(params[:page]).per(50)
    @group_member = GroupMember.new
  end

  def create
    access_level = params[:access_level]
    user_ids = params[:user_ids].split(',')

    @group.add_users(user_ids, access_level)
    group_members = @group.group_members.where(user_id: user_ids)

    group_members.each do |group_member|
      log_audit_event(group_member, action: :create)
    end

    redirect_to group_group_members_path(@group), notice: 'Users were successfully added.'
  end

  def update
    @member = @group.group_members.find(params[:id])
    old_access_level = @member.human_access

    if @member.update_attributes(member_params)
      log_audit_event(@member, action: :update, old_access_level: old_access_level)
    end
  end

  def destroy
    @group_member = @group.group_members.find(params[:id])

    if can?(current_user, :destroy_group_member, @group_member)  # May fail if last owner.
      @group_member.destroy
      log_audit_event(@group_member, action: :destroy)

      respond_to do |format|
        format.html { redirect_to group_group_members_path(@group), notice: 'User was  successfully removed from group.' }
        format.js { render nothing: true }
      end
    else
      return render_403
    end
  end

  def leave
    @group_member = @group.group_members.where(user_id: current_user.id).first

    if can?(current_user, :destroy_group_member, @group_member)
      @group_member.destroy
      log_audit_event(@group_member, action: :destroy)

      redirect_to(dashboard_groups_path, info: "You left #{group.name} group.")
    else
      return render_403
    end
  end

  protected

  def member_params
    params.require(:group_member).permit(:access_level, :user_id)
  end

  def log_audit_event(member, options = {})
    AuditEventService.new(current_user, @group, options).
      for_member(member).security_event
  end
end
