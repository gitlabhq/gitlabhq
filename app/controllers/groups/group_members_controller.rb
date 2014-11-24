class Groups::GroupMembersController < ApplicationController
  before_filter :group

  # Authorize
  before_filter :authorize_admin_group!

  layout 'group'

  def create
    access_level = params[:access_level]
    user_ids = params[:user_ids].split(',')

    @group.add_users(user_ids, access_level)

    users = User.where(id: user_ids).pluck(:id, :name)
    users.each do |user|
      details = {
        add: "user_access",
        as: Gitlab::Access.options_with_owner.key(access_level.to_i),
        target_id: user[0],
        target_type: "User",
        target_details: user[1],
      }
      AuditEventService.new(current_user, @group, details).security_event
    end

    redirect_to members_group_path(@group), notice: 'Users were successfully added.'
  end

  def update
    @member = @group.group_members.find(params[:id])
    old_access_level = @member.human_access

    if @member.update_attributes(member_params)
      details = {
        change: "access_level",
        from:  old_access_level,
        to: @member.human_access,
        target_id: @member.user_id,
        target_type: "User",
        target_details: @member.user.name,
      }
      AuditEventService.new(current_user, @group, details).security_event
    end
  end

  def destroy
    @users_group = @group.group_members.find(params[:id])

    if can?(current_user, :destroy, @users_group)  # May fail if last owner.
      user_id = @users_group.id
      user_name = @users_group.user.name
      if @users_group.destroy
        details = {
          remove: "user_access",
          target_id: user_id,
          target_type: "User",
          target_details: user_name,
        }
        AuditEventService.new(current_user, @group, details).security_event
      end

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
