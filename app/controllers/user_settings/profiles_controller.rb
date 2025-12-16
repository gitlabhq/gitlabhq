# frozen_string_literal: true

module UserSettings
  class ProfilesController < ApplicationController
    include ActionView::Helpers::SanitizeHelper
    include Gitlab::Tracking
    include AuthHelper

    before_action :user
    skip_before_action :require_email, only: [:show, :update]
    before_action :validate_email_otp_preference_modification, only: [:update]

    feature_category :user_profile, [:show, :update]

    urgency :low, [:show, :update]

    def show; end

    def update
      respond_to do |format|
        result = Users::UpdateService.new(current_user, user_params.merge(user: @user)).execute(check_password: true)

        if result[:status] == :success
          message = s_("Profiles|Profile was successfully updated")

          format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
          format.json do
            render json: {
              message: message,
              email_help_text: view_context.sanitized_email_help_text(@user)
            }
          end
        else
          format.html do
            redirect_back_or_default(default: { action: 'show' }, options: { alert: result[:message] })
          end
          format.json { render json: result }
        end
      end
    end

    private

    def user
      @user = current_user
    end

    def user_params_attributes
      [
        :achievements_enabled,
        :avatar,
        :bio,
        :bluesky,
        :commit_email,
        :discord,
        :email,
        :gitpod_enabled,
        :hide_no_password,
        :hide_no_ssh_key,
        :hide_project_limit,
        :include_private_contributions,
        :job_title,
        :linkedin,
        :location,
        :mastodon,
        :name,
        :orcid,
        :user_detail_organization,
        :private_profile,
        :pronouns,
        :pronunciation,
        :public_email,
        :timezone,
        :twitter,
        :username,
        :validation_password,
        :website_url,
        :github,
        { status: [:emoji, :message, :availability, :clear_status_after] },
        :email_otp_required_as_boolean
      ]
    end

    def user_params
      @user_params ||= params.require(:user).permit(user_params_attributes)
    end

    def current_password_params
      params.permit(:current_password)
    end

    # Provides user-facing validation for email OTP enrollment changes.
    # Model-level validation in Users::UpdateService ensures consistency
    # when records are updated through the service layer.
    def validate_email_otp_preference_modification
      return unless user_params.include?(:email_otp_required_as_boolean)

      return if current_user.email_otp_required_as_boolean ==
        ActiveModel::Type::Boolean.new.cast(user_params[:email_otp_required_as_boolean])

      unless current_user.can_modify_email_otp_enrollment?
        respond_with_error(s_("Profiles|You are not permitted to change email OTP enrollment"))
        return
      end

      return if current_password_matches?

      respond_with_error(s_("Profiles|You must provide a valid current password."))
    end

    def respond_with_error(message)
      respond_to do |format|
        format.html do
          redirect_back_or_default(default: { action: 'show' }, options: { alert: message })
        end
        format.json { render json: { message: message }, status: :forbidden }
      end
    end

    def current_password_matches?
      return true unless current_password_required?
      return true if current_user.valid_password?(current_password_params[:current_password])

      current_user.increment_failed_attempts!

      false
    end
  end
end

# Added for JiHu
# Used in https://jihulab.com/gitlab-cn/gitlab/-/blob/main-jh/jh/app/controllers/jh/user_settings/profiles_controller.rb
UserSettings::ProfilesController.prepend_mod
