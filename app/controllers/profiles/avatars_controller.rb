class Profiles::AvatarsController < Profiles::ApplicationController
  def destroy
    @user = current_user
    @user.remove_avatar!

    Users::UpdateService.new(@user, @user).execute

    redirect_to profile_path, status: 302
  end
end
