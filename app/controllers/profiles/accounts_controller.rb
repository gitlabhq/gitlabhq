class Profiles::AccountsController < ApplicationController
  layout "profile"

  def show
    @user = current_user
  end
end
