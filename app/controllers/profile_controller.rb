class ProfileController < ApplicationController
  before_filter :user

  def show
  end

  def design
  end

  def update
    @user.update_attributes(params[:user])
    redirect_to :back
  end

  def token
  end

  def password_update
    params[:user].reject!{ |k, v| k != "password" && k != "password_confirmation"}

    if @user.update_attributes(params[:user])
      flash[:notice] = "Password was successfully updated. Please login with it"
      redirect_to new_user_session_path
    else
      render action: "password"
    end
  end

  def reset_private_token
    current_user.reset_authentication_token!
    redirect_to profile_account_path
  end

  def history
    @events = current_user.recent_events.page(params[:page]).per(20)
  end

  private

  def user
    @user = current_user
  end
end
