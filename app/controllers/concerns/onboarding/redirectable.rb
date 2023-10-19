# frozen_string_literal: true

module Onboarding
  module Redirectable
    extend ActiveSupport::Concern

    private

    def after_sign_up_path
      if onboarding_status.single_invite?
        flash[:notice] = helpers.invite_accepted_notice(onboarding_status.last_invited_member)
        onboarding_status.last_invited_member_source.activity_path
      else
        # Invites will come here if there is more than 1.
        path_for_signed_in_user
      end
    end

    def path_for_signed_in_user
      stored_location_for(:user) || last_member_activity_path
    end

    def last_member_activity_path
      return dashboard_projects_path unless onboarding_status.last_invited_member_source.present?

      onboarding_status.last_invited_member_source.activity_path
    end
  end
end

Onboarding::Redirectable.prepend_mod
