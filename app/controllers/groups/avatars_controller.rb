class Groups::AvatarsController < Groups::ApplicationController
  before_action :authorize_admin_group!

  def destroy
    @group.remove_avatar!
    @group.save

    redirect_to edit_group_path(@group)
  end
end
