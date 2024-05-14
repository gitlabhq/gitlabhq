# frozen_string_literal: true

module Admin
  class InitialSetupController < ApplicationController
    include CheckInitialSetup

    skip_before_action :authenticate_admin!
    skip_before_action :authenticate_user!

    before_action :check_initial_setup

    layout 'devise'

    feature_category :system_access

    def new; end

    def update
      @result = Users::UpdateService.new(@user, user_params).execute(&:skip_reconfirmation!)

      if @result[:status] == :success
        clean_up_non_primary_emails(@user)
        redirect_to new_user_session_path, notice: _('Initial account configured! Please sign in.')
      else
        render :new
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation).merge(
        user: @user,
        password_automatically_set: nil,
        password_expires_at: nil
      )
    end

    def check_initial_setup
      if in_initial_setup_state?
        @user = User.admins.last
        return
      end

      # redirect to root_path to avoid potential redirect loop on sessions_controller
      redirect_to root_path, notice: _("Initial setup complete!")
    end

    # the initial email generated randomly by fixtures, or from the GITLAB_ROOT_EMAIL env var
    # should be cleaned up if different than the assigned-via-UI initial account email
    def clean_up_non_primary_emails(user)
      user.emails.each do |email|
        email.destroy unless email.user_primary_email?
      end
    end
  end
end
