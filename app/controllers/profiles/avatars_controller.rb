class Profiles::AvatarsController < Profiles::ApplicationController
  def destroy
    @user = current_user
    @user.remove_avatar!

    @user.save
    @user.reset_events_cache

    redirect_to profile_path
  end
end
