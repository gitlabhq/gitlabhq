class ProfileController < ApplicationController
  layout "profile"
  def show
    @user = current_user
  end

  def design
    @user = current_user
  end

  def update
    @user = current_user
    @user.update_attributes(params[:user])
    redirect_to :back
  end

  def password
    @user = current_user
  end

  def password_update
    params[:user].reject!{ |k, v| k != "password" && k != "password_confirmation"}
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:notice] = "Password was successfully updated. Please login with it"
      redirect_to new_user_session_path
    else
      render :action => "password"
    end
  end

  def reset_private_token
    current_user.reset_authentication_token!
    redirect_to profile_password_path
  end
end
