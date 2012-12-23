class ProfilesController < ApplicationController
  before_filter :user
  layout 'profile'

  def show
  end

  def design
  end

  def account
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:notice] = "Profile was successfully updated"
    else
      flash[:alert] = "Failed to update profile"
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def token
  end

  def update_password
    params[:user].reject!{ |k, v| k != "password" && k != "password_confirmation"}

    if @user.update_attributes(params[:user])
      flash[:notice] = "Password was successfully updated. Please login with it"
      redirect_to new_user_session_path
    else
      render 'account'
    end
  end

  def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = "Token was successfully updated"
    end

    redirect_to account_profile_path
  end

  def history
    @events = current_user.recent_events.page(params[:page]).per(20)
  end

  def update_username
    @user.update_attributes(username: params[:user][:username])

    respond_to do |format|
      format.js
    end
  end

  private

  def user
    @user = current_user
  end
end
