# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include GoogleSyndicationCSP
    include ::Gitlab::Utils::StrongMemoize

    layout 'minimal'
    skip_before_action :check_two_factor_requirement

    helper_method :welcome_update_params
    helper_method :onboarding_status

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

    def authenticate_user!
      return if current_user

      redirect_to new_user_registration_path
    end

    def completed_welcome_step?
      !current_user.setup_for_company.nil?
    end

    def update_params
      params.require(:user).permit(:role, :setup_for_company)
    end

    def path_for_signed_in_user(user)
      stored_location_for(user) || last_member_activity_path
    end

    def last_member_activity_path
      return dashboard_projects_path unless onboarding_status.last_invited_member_source.present?

      onboarding_status.last_invited_member_source.activity_path
    end

    def update_success_path
      if onboarding_status.invite_with_tasks_to_be_done?
        issues_dashboard_path(assignee_username: current_user.username)
      elsif onboarding_status.continue_full_onboarding? # trials/regular registration on .com
        signup_onboarding_path
      elsif onboarding_status.single_invite? # invites w/o tasks due to order
        flash[:notice] = helpers.invite_accepted_notice(onboarding_status.last_invited_member)
        onboarding_status.last_invited_member_source.activity_path
      else
        # Subscription registrations goes through here as well.
        # Invites will come here too if there is more than 1.
        path_for_signed_in_user(current_user)
      end
    end

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

    def onboarding_status
      Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end

Registrations::WelcomeController.prepend_mod_with('Registrations::WelcomeController')
