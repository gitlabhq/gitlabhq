# frozen_string_literal: true

class Profiles::AvatarsController < Profiles::ApplicationController
  feature_category :users

  def destroy
    @user = current_user

    Users::UpdateService.new(current_user, user: @user).execute { |user| user.remove_avatar! }

    redirect_to profile_path, status: :found
  end
end
