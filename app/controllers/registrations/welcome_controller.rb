# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    include OneTrustCSP

    layout 'minimal'
    skip_before_action :authenticate_user!, :required_signup_info, :check_two_factor_requirement, only: [:show, :update]
    before_action :require_current_user

    feature_category :authentication_and_authorization

    def show
      return redirect_to path_for_signed_in_user(current_user) if completed_welcome_step?
    end

    def update
      result = ::Users::SignupService.new(current_user, update_params).execute

      if result[:status] == :success
        return redirect_to issues_dashboard_path(assignee_username: current_user.username) if show_tasks_to_be_done?

        return redirect_to update_success_path if show_signup_onboarding?

        members = current_user.members

        if members.count == 1 && members.last.source.present?
          redirect_to members_activity_path(members), notice: helpers.invite_accepted_notice(members.last)
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
      params.require(:user).permit(:role, :other_role, :setup_for_company)
    end

    def requires_confirmation?(user)
      return false if user.confirmed?
      return false if Feature.enabled?(:soft_email_confirmation)

      true
    end

    def path_for_signed_in_user(user)
      return users_almost_there_path(email: user.email) if requires_confirmation?(user)

      stored_url = stored_location_for(user)
      if ::Feature.enabled?(:about_your_company_registration_flow) &&
          stored_url&.include?(new_users_sign_up_company_path)
        company_params = update_params.slice(:role, :other_role, :registration_objective)
                          .merge(params.permit(:jobs_to_be_done_other))
        redirect_uri = Gitlab::Utils.add_url_parameters(stored_url, company_params)
        store_location_for(:user, redirect_uri)
      else
        stored_url || members_activity_path(user.members)
      end
    end

    def members_activity_path(members)
      return dashboard_projects_path unless members.any?
      return dashboard_projects_path unless members.last.source.present?

      members.last.source.activity_path
    end

    # overridden in EE
    def show_signup_onboarding?
      false
    end

    def show_tasks_to_be_done?
      MemberTask.for_members(current_user.members).exists?
    end

    # overridden in EE
    def update_success_path
    end
  end
end

Registrations::WelcomeController.prepend_mod_with('Registrations::WelcomeController')
