# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP

    layout 'minimal'
    skip_before_action :authenticate_user!, :required_signup_info, :check_two_factor_requirement, only: [:show, :update]
    before_action :require_current_user

    helper_method :welcome_update_params

    feature_category :user_management

    def show
      return redirect_to path_for_signed_in_user(current_user) if completed_welcome_step?

      track_event('render')
    end

    def update
      result = ::Users::SignupService.new(current_user, update_params).execute

      if result.success?
        track_event('successfully_submitted_form')

        redirect_to update_success_path
      else
        render :show
      end
    end

    private

    def registering_from_invite?(members)
      members.count == 1 && members.last.source.present?
    end

    def require_current_user
      return redirect_to new_user_registration_path unless current_user
    end

    def completed_welcome_step?
      current_user.role.present? && !current_user.setup_for_company.nil?
    end

    def update_params
      params.require(:user).permit(:role, :setup_for_company)
    end

    def requires_confirmation?(user)
      return false if user.confirmed?
      return false unless Gitlab::CurrentSettings.email_confirmation_setting_hard?

      true
    end

    def path_for_signed_in_user(user)
      return users_almost_there_path(email: user.email) if requires_confirmation?(user)

      stored_location_for(user) || members_activity_path(user.members)
    end

    def members_activity_path(members)
      return dashboard_projects_path unless members.any?
      return dashboard_projects_path unless members.last.source.present?

      members.last.source.activity_path
    end

    # overridden in EE
    def redirect_to_signup_onboarding?
      false
    end

    def redirect_for_tasks_to_be_done?
      MemberTask.for_members(current_user.members).exists?
    end

    def update_success_path
      return issues_dashboard_path(assignee_username: current_user.username) if redirect_for_tasks_to_be_done?

      return signup_onboarding_path if redirect_to_signup_onboarding?

      members = current_user.members

      if registering_from_invite?(members)
        flash[:notice] = helpers.invite_accepted_notice(members.last)
        members_activity_path(members)
      else
        # subscription registrations goes through here as well
        path_for_signed_in_user(current_user)
      end
    end

    # overridden in EE
    def signup_onboarding_path; end

    # overridden in EE
    def track_event(action); end

    # overridden in EE
    def welcome_update_params
      {}
    end
  end
end

Registrations::WelcomeController.prepend_mod_with('Registrations::WelcomeController')
