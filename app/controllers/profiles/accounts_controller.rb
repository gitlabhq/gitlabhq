class Profiles::AccountsController < ApplicationController
  layout "profile"

  def show
    @user = current_user
    @applications = current_user.oauth_applications
    @authorized_applications = Doorkeeper::Application.authorized_for(current_user)
  end
end
