class Profiles::AvatarsController < ApplicationController
  layout "profile"

  def destroy
    @user = current_user
    @user.remove_avatar!

    @user.save
    redirect_to profile_path
  end
end
