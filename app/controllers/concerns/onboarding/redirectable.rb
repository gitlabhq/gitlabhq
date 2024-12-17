# frozen_string_literal: true

module Onboarding
  module Redirectable
    extend ActiveSupport::Concern

    private

    def after_sign_up_path
      if onboarding_status_presenter.single_invite?
        flash[:notice] = helpers.invite_accepted_notice(onboarding_status_presenter.last_invited_member)
        polymorphic_path(onboarding_status_presenter.last_invited_member_source)
      else
        # Invites will come here if there is more than 1.
        path_for_signed_in_user
      end
    end

    def path_for_signed_in_user
      stored_location_for(:user) || last_member_source_path
    end

    def last_member_source_path
      return dashboard_projects_path unless onboarding_status_presenter.last_invited_member_source.present?

      polymorphic_path(onboarding_status_presenter.last_invited_member_source)
    end
  end
end

Onboarding::Redirectable.prepend_mod
