#encoding: utf-8
class ProfilesController < Profiles::ApplicationController
  include ActionView::Helpers::SanitizeHelper

  before_action :user
  before_action :authorize_change_username!, only: :update_username
  skip_before_action :require_email, only: [:show, :update]

  def show
  end

  def update
    user_params.except!(:email) if @user.ldap_user?

    respond_to do |format|
      if @user.update_attributes(user_params)
        message = "个人资料已成功更新"
        format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
        format.json { render json: { message: message } }
      else
        message = @user.errors.full_messages.uniq.join('. ')
        format.html { redirect_back_or_default(default: { action: 'show' }, options: { alert: "更新个人资料失败。#{message}" }) }
        format.json { render json: { message: message }, status: :unprocessable_entity }
      end
    end
  end

  def reset_private_token
    if current_user.reset_authentication_token!
      flash[:notice] = "令牌已成功更新"
    end

    redirect_to profile_account_path
  end

  def audit_log
    @events = AuditEvent.where(entity_type: "User", entity_id: current_user.id).
      order("created_at DESC").
      page(params[:page])
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
