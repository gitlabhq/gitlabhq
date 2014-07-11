class ProfilesController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_filter :user
  before_filter :authorize_change_username!, only: :update_username
  skip_before_filter :require_email, only: [:show, :update]

  layout 'profile'

  def show
  end

  def design
  end

  def update
    user_params.except!(:email) if @user.ldap_user?

    if @user.update_attributes(user_params)
      flash[:notice] = "Profile was successfully updated"
    else
      flash[:alert] = "Failed to update profile"
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = "Token was successfully updated"
    end

    redirect_to profile_account_path
  end

  def history
    @events = current_user.recent_events.page(params[:page]).per(20)
  end

  def update_username
    @user.update_attributes(username: user_params[:username])

    respond_to do |format|
      format.js
    end
  end

  private

  def user
    @user = current_user
  end

  def authorize_change_username!
    return render_404 unless @user.can_change_username?
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :bio, :name, :username,
      :skype, :linkedin, :twitter, :website_url, :color_scheme_id, :theme_id,
      :avatar, :hide_no_ssh_key,
    )
  end
end
