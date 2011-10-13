class ProfileController < ApplicationController
  def show
    @user = current_user
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
end
