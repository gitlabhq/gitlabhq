class Groups::LdapsController < Groups::ApplicationController
  before_filter :group
  before_filter :authorize_admin_group!

  def reset_access
    LdapGroupResetService.new.execute(group, current_user)

    redirect_to members_group_path(@group), notice: 'Access reset complete'
  end
end
