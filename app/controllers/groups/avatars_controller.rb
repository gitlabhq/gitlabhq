class Groups::AvatarsController < Groups::ApplicationController
  before_action :authorize_admin_group!

  skip_cross_project_access_check :destroy

  def destroy
    @group.remove_avatar!
    @group.save

    redirect_to edit_group_path(@group), status: 302
  end
end
