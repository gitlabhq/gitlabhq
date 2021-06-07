# frozen_string_literal: true

class ProfilesController < Profiles::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include Gitlab::Tracking

  before_action :user
  before_action :authorize_change_username!, only: :update_username
  skip_before_action :require_email, only: [:show, :update]
  before_action do
    push_frontend_feature_flag(:webauthn)
  end

  feature_category :users

  def show
  end

  def update
    respond_to do |format|
      result = Users::UpdateService.new(current_user, user_params.merge(user: @user)).execute

      if result[:status] == :success
        message = s_("Profiles|Profile was successfully updated")

        format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
        format.json { render json: { message: message } }
      else
        format.html { redirect_back_or_default(default: { action: 'show' }, options: { alert: result[:message] }) }
        format.json { render json: result }
      end
    end
  end

  def reset_incoming_email_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_incoming_email_token!
    end

    flash[:notice] = s_("Profiles|Incoming email token was successfully reset")

    redirect_to profile_personal_access_tokens_path
  end

  def reset_feed_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_feed_token!
    end

    flash[:notice] = s_('Profiles|Feed token was successfully reset')

    redirect_to profile_personal_access_tokens_path
  end

  def reset_static_object_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_static_object_token!
    end

    redirect_to profile_personal_access_tokens_path,
      notice: s_('Profiles|Static object token was successfully reset')
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def audit_log
    @events = AuditEvent.where(entity_type: "User", entity_id: current_user.id)
      .order("created_at DESC")
      .page(params[:page])

    Gitlab::Tracking.event(self.class.name, 'search_audit_event', user: current_user)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def update_username
    result = Users::UpdateService.new(current_user, user: @user, username: username_param).execute

    respond_to do |format|
      if result[:status] == :success
        message = s_("Profiles|Username successfully changed")

        format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
        format.json { render json: { message: message }, status: :ok }
      else
        message = s_("Profiles|Username change failed - %{message}") % { message: result[:message] }

        format.html { redirect_back_or_default(default: { action: 'show' }, options: { alert: message }) }
        format.json { render json: { message: message }, status: :unprocessable_entity }
      end
    end
  end

  private

  def user
    @user = current_user
  end

  def authorize_change_username!
    return render_404 unless @user.can_change_username?
  end

  def username_param
    @username_param ||= user_params.require(:username)
  end

  def user_params
    @user_params ||= params.require(:user).permit(
      :avatar,
      :bio,
      :email,
      :role,
      :gitpod_enabled,
      :hide_no_password,
      :hide_no_ssh_key,
      :hide_project_limit,
      :linkedin,
      :location,
      :name,
      :public_email,
      :commit_email,
      :skype,
      :twitter,
      :username,
      :website_url,
      :organization,
      :private_profile,
      :include_private_contributions,
      :timezone,
      :job_title,
      :pronouns,
      status: [:emoji, :message, :availability]
    )
  end
end
