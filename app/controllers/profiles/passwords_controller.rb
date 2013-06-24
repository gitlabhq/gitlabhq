class Profiles::PasswordsController < ApplicationController
  layout 'navless'

  skip_before_filter :check_password_expiration

  before_filter :set_user
  before_filter :set_title

  def new
  end

  def create
    new_password = params[:user][:password]
    new_password_confirmation = params[:user][:password_confirmation]

    result = @user.update_attributes(
      password: new_password,
      password_confirmation: new_password_confirmation
    )

    if result
      @user.update_attributes(password_expires_at: nil)
      redirect_to root_path, notice: 'Password successfully changed'
    else
      render :new
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_title
    @title = "New password"
  end
end
