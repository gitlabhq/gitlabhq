class Groups::AvatarsController < ApplicationController
  layout "profile"

  def destroy
    @group = Group.find_by(path: params[:group_id])
    @group.remove_avatar!

    @group.save

    redirect_to edit_group_path(@group)
  end
end
