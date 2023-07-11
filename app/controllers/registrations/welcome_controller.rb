# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include ::Gitlab::Utils::StrongMemoize

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
        successful_update_hooks
        redirect_to update_success_path
      else
        render :show
      end
    end

    private

    def registering_from_invite?(members)
      # If there are more than one member it will mean we have been invited to multiple projects/groups and
      # are not able to distinguish which one we should putting the user in after registration
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

    def path_for_signed_in_user(user)
      stored_location_for(user) || members_activity_path(user.members)
    end

    def members_activity_path(members)
      return dashboard_projects_path unless members.any?
      return dashboard_projects_path unless members.last.source.present?

      members.last.source.activity_path
    end

    # overridden in EE
    def complete_signup_onboarding?
      false
    end

    def invites_with_tasks_to_be_done?
      MemberTask.for_members(user_members).exists?
    end

    def update_success_path
      if invites_with_tasks_to_be_done?
        issues_dashboard_path(assignee_username: current_user.username)
      elsif complete_signup_onboarding? # trials/regular registration on .com
        signup_onboarding_path
      elsif registering_from_invite?(user_members) # invites w/o tasks due to order
        flash[:notice] = helpers.invite_accepted_notice(user_members.last)
        members_activity_path(user_members)
      else
        # Subscription registrations goes through here as well.
        # Invites will come here too if there is more than 1.
        path_for_signed_in_user(current_user)
      end
    end

    def user_members
      current_user.members
    end
    strong_memoize_attr :user_members

    # overridden in EE
    def successful_update_hooks; end

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
