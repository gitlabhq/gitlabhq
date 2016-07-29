class Groups::LdapsController < Groups::ApplicationController
  before_action :group
  before_action :authorize_admin_group!

  def reset_access
    LdapGroupResetService.new.execute(group, current_user)

    redirect_to group_group_members_path(@group), notice: 'Access reset complete'
  end
end
