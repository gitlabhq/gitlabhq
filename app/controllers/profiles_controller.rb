class ProfilesController < Profiles::ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :user
  before_action :authorize_change_username!, only: :update_username
  skip_before_action :require_email, only: [:show, :update]

  def show
  end

  def applications
    @applications = current_user.oauth_applications
    @authorized_tokens = current_user.oauth_authorized_tokens
    @authorized_apps = @authorized_tokens.map(&:application).uniq
  end

  def update
    user_params.except!(:email) if @user.ldap_user?

    if @user.update_attributes(user_params)
      flash[:notice] = "Profile was successfully updated"
    else
      messages = @user.errors.full_messages.uniq.join('. ')
      flash[:alert] = "Failed to update profile. #{messages}"
    end

    respond_to do |format|
      format.html { redirect_to :back }
    end
  end

  def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = "Token was successfully updated"
    end

    redirect_to profile_account_path
  end

  def history
    @events = current_user.recent_events.page(params[:page]).per(PER_PAGE)
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
      :avatar,
      :bio,
      :email,
      :hide_no_password,
      :hide_no_ssh_key,
      :linkedin,
      :location,
      :name,
      :password,
      :password_confirmation,
      :public_email,
      :skype,
      :twitter,
      :username,
      :website_url
    )
  end
end
