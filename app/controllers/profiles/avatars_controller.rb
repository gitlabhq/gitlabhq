# frozen_string_literal: true

class Profiles::AvatarsController < Profiles::ApplicationController
  feature_category :user_profile

  def destroy
    @user = current_user

    Users::UpdateService.new(current_user, user: @user).execute(&:remove_avatar!)

    redirect_to user_settings_profile_path, status: :found
  end
end
