# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    layout 'welcome'
    skip_before_action :authenticate_user!, :required_signup_info, :check_two_factor_requirement, only: [:show, :update]
    before_action :require_current_user

    feature_category :authentication_and_authorization

    def show
      return redirect_to path_for_signed_in_user(current_user) if completed_welcome_step?
    end

    def update
      result = ::Users::SignupService.new(current_user, update_params).execute

      if result[:status] == :success
        process_gitlab_com_tracking

        return redirect_to new_users_sign_up_group_path if experiment_enabled?(:onboarding_issues) && show_onboarding_issues_experiment?

        redirect_to path_for_signed_in_user(current_user)
      else
        render :show
      end
    end

    private

    def require_current_user
      return redirect_to new_user_registration_path unless current_user
    end

    def completed_welcome_step?
      current_user.role.present? && !current_user.setup_for_company.nil?
    end

    def process_gitlab_com_tracking
      return false unless ::Gitlab.com?
      return false unless show_onboarding_issues_experiment?

      track_experiment_event(:onboarding_issues, 'signed_up')
      record_experiment_user(:onboarding_issues)
    end

    def update_params
      params.require(:user).permit(:role, :setup_for_company)
    end

    def requires_confirmation?(user)
      return false if user.confirmed?
      return false if Feature.enabled?(:soft_email_confirmation)

      true
    end

    def path_for_signed_in_user(user)
      return users_almost_there_path if requires_confirmation?(user)

      stored_location_for(user) || dashboard_projects_path
    end

    def show_onboarding_issues_experiment?
      !helpers.in_subscription_flow? &&
        !helpers.in_invitation_flow? &&
        !helpers.in_oauth_flow? &&
        !helpers.in_trial_flow?
    end
  end
end

Registrations::WelcomeController.prepend_if_ee('EE::Registrations::WelcomeController')
