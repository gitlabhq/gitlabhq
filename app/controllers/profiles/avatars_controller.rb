class Profiles::AvatarsController < Profiles::ApplicationController
  def destroy
    @user = current_user
    @user.remove_avatar!

    @user.save

    redirect_to profile_path, status: 302
  end
end
