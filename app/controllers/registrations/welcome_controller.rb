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
        return redirect_to new_users_sign_up_group_path if show_signup_onboarding?

        if current_user.members.count == 1
          redirect_to path_for_signed_in_user(current_user), notice: helpers.invite_accepted_notice(current_user.members.last)
        else
          redirect_to path_for_signed_in_user(current_user)
        end
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

    def update_params
      params.require(:user).permit(:role, :other_role, :setup_for_company, :email_opted_in)
    end

    def requires_confirmation?(user)
      return false if user.confirmed?
      return false if Feature.enabled?(:soft_email_confirmation)

      true
    end

    def path_for_signed_in_user(user)
      return users_almost_there_path if requires_confirmation?(user)

      stored_location_for(user) || members_activity_path(user)
    end

    def members_activity_path(user)
      return dashboard_projects_path unless user.members.count >= 1

      case user.members.last.source
      when Project
        activity_project_path(user.members.last.source)
      when Group
        activity_group_path(user.members.last.source)
      else
        dashboard_projects_path
      end
    end

    def show_signup_onboarding?
      false
    end
  end
end

Registrations::WelcomeController.prepend_if_ee('EE::Registrations::WelcomeController')
