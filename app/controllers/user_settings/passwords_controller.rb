# frozen_string_literal: true

module UserSettings
  class PasswordsController < ApplicationController
    include Gitlab::Tracking::Helpers::WeakPasswordErrorEvent

    skip_before_action :check_password_expiration, only: [:new, :create]
    skip_before_action :check_two_factor_requirement, only: [:new, :create]
    skip_before_action :active_user_check, only: [:new, :create]

    before_action :set_user
    before_action :authorize_change_password!

    layout :determine_layout

    feature_category :system_access

    def new
      current_user.activate if user_signed_in? && current_user.deactivated?
    end

    def create
      unless @user.password_automatically_set || @user.valid_password?(user_params[:password])
        redirect_to new_user_settings_password_path, alert: _('You must provide a valid current password')
        return
      end

      result = Users::UpdateService.new(current_user, password_attributes.merge(user: @user)).execute

      if result[:status] == :success
        Users::UpdateService.new(current_user, user: @user, password_expires_at: nil).execute

        redirect_to root_path, notice: _('Password successfully changed')
      else
        track_weak_password_error(@user, self.class.name, 'create')
        render :new
      end
    end

    def edit; end

    def update
      unless @user.password_automatically_set || @user.valid_password?(user_params[:password])
        handle_invalid_current_password_attempt!

        redirect_to edit_user_settings_password_path, alert: _('You must provide a valid current password')
        return
      end

      result = Users::UpdateService.new(current_user, password_attributes.merge(user: @user)).execute

      if result[:status] == :success
        flash[:notice] = _('Password was successfully updated. Please sign in again.')
        redirect_to new_user_session_path
      else
        track_weak_password_error(@user, self.class.name, 'update')
        @user.reset
        render 'edit'
      end
    end

    def reset
      current_user.send_reset_password_instructions
      redirect_to edit_user_settings_password_path, notice: _('We sent you an email with reset password instructions')
    end

    private

    def set_user
      @user = current_user
    end

    def determine_layout
      if [:new, :create].include?(action_name.to_sym)
        'minimal'
      else
        'profile'
      end
    end

    def authorize_change_password!
      render_404 unless @user.allow_password_authentication?
    end

    def handle_invalid_current_password_attempt!
      Gitlab::AppLogger.info(message: 'Invalid current password when attempting to update user password',
        username: @user.username, ip: request.remote_ip)

      @user.increment_failed_attempts!
    end

    def user_params
      params.require(:user).permit(:password, :new_password, :password_confirmation)
    end

    def password_attributes
      {
        password: user_params[:new_password],
        password_confirmation: user_params[:password_confirmation],
        password_automatically_set: false
      }
    end
  end
end

UserSettings::PasswordsController.prepend_mod
