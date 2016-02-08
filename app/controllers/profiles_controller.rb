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
    @authorized_anonymous_tokens = @authorized_tokens.reject(&:application)
    @authorized_apps = @authorized_tokens.map(&:application).uniq - [nil]
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
      format.html { redirect_back_or_default(default: { action: 'show' }) }
    end
  end

  def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = "Token was successfully updated"
    end

    redirect_to profile_account_path
  end

  def audit_log
    @events = AuditEvent.where(entity_type: "User", entity_id: current_user.id).
      order("created_at DESC").
      page(params[:page]).
      per(PER_PAGE)
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
      :avatar_crop_x,
      :avatar_crop_y,
      :avatar_crop_size,
      :avatar,
      :bio,
      :email,
      :hide_no_password,
      :hide_no_ssh_key,
      :hide_project_limit,
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
