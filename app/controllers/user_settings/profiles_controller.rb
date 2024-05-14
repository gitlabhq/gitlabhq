# frozen_string_literal: true

module UserSettings
  class ProfilesController < ApplicationController
    include ActionView::Helpers::SanitizeHelper
    include Gitlab::Tracking

    before_action :user
    skip_before_action :require_email, only: [:show, :update]
    feature_category :user_profile, [:show, :update]

    urgency :low, [:show, :update]

    def show; end

    def update
      respond_to do |format|
        result = Users::UpdateService.new(current_user, user_params.merge(user: @user)).execute(check_password: true)

        if result[:status] == :success
          message = s_("Profiles|Profile was successfully updated")

          format.html { redirect_back_or_default(default: { action: 'show' }, options: { notice: message }) }
          format.json { render json: { message: message } }
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
        { status: [:emoji, :message, :availability, :clear_status_after] }
      ]
    end

    def user_params
      @user_params ||= params.require(:user).permit(user_params_attributes)
    end
  end
end

# Added for JiHu
# Used in https://jihulab.com/gitlab-cn/gitlab/-/blob/main-jh/jh/app/controllers/jh/user_settings/profiles_controller.rb
UserSettings::ProfilesController.prepend_mod
