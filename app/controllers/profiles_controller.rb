class ProfilesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_filter :user
  before_filter :authorize_change_password!, only: :update_password
  before_filter :authorize_change_username!, only: :update_username

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
    password_attributes = params[:user].select do |key, value|
      %w(password password_confirmation).include?(key.to_s)
    end

    unless @user.valid_password?(params[:user][:current_password])
      redirect_to account_profile_path, alert: 'You must provide a valid current password'
      return
    end

    if @user.update_attributes(password_attributes)
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

  def authorize_change_password!
    return render_404 if @user.ldap_user?
  end

  def authorize_change_username!
    return render_404 unless @user.can_change_username?
  end
end
