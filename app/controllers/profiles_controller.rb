# frozen_string_literal: true

class ProfilesController < Profiles::ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include Gitlab::Tracking

  before_action :user
  before_action :authorize_change_username!, only: :update_username
  before_action only: :update_username do
    check_rate_limit!(:profile_update_username, scope: current_user)
  end

  feature_category :user_profile, [:reset_incoming_email_token, :reset_feed_token,
                            :reset_static_object_token, :update_username]

  def reset_incoming_email_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_incoming_email_token!
    end

    flash[:notice] = s_("Profiles|Incoming email token was successfully reset")

    redirect_to user_settings_personal_access_tokens_path
  end

  def reset_feed_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_feed_token!
    end

    flash[:notice] = s_('Profiles|Feed token was successfully reset')

    redirect_to user_settings_personal_access_tokens_path
  end

  def reset_static_object_token
    Users::UpdateService.new(current_user, user: @user).execute! do |user|
      user.reset_static_object_token!
    end

    redirect_to user_settings_personal_access_tokens_path,
      notice: s_('Profiles|Static object token was successfully reset')
  end

  def update_username
    result = Users::UpdateService.new(current_user, user: @user, username: username_param).execute

    respond_to do |format|
      if result[:status] == :success
        message = s_("Profiles|Username successfully changed")

        format.html { redirect_back_or_default(default: user_settings_profile_path, options: { notice: message }) }
        format.json { render json: { message: message }, status: :ok }
      else
        message = s_("Profiles|Username change failed - %{message}") % { message: result[:message] }

        format.html { redirect_back_or_default(default: user_settings_profile_path, options: { alert: message }) }
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

  def user_params_attributes
    [
      :avatar,
      :bio,
      :discord,
      :email,
      :role,
      :gitpod_enabled,
      :hide_no_password,
      :hide_no_ssh_key,
      :hide_project_limit,
      :linkedin,
      :location,
      :mastodon,
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
      :achievements_enabled,
      :timezone,
      :job_title,
      :pronouns,
      :pronunciation,
      :validation_password,
      status: [:emoji, :message, :availability, :clear_status_after]
    ]
  end

  def user_params
    @user_params ||= params.require(:user).permit(user_params_attributes)
  end
end

ProfilesController.prepend_mod
