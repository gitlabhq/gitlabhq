class Groups::LdapsController < ApplicationController
  before_filter :group
  before_filter :authorize_admin_group!

  def reset_access
    LdapGroupResetService.new.execute(group, current_user)

    redirect_to members_group_path(@group), notice: 'Access reset complete'
  end

  private

  def group
    @group ||= Group.find_by(path: params[:group_id])
  end

  def authorize_admin_group!
    unless can?(current_user, :manage_group, group)
      return render_404
    end
  end
end
