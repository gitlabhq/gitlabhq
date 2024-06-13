# frozen_string_literal: true

module Users
  class RegistrationsBuildService < BuildService
    extend ::Gitlab::Utils::Override

    private

    override :build_user_detail
    def build_user_detail
      # This will ensure we either load an existing record or create it.
      # TODO: Eventually we should specifically build here once we get away from the lazy loading in
      # https://gitlab.com/gitlab-org/gitlab/-/issues/462919.
      if Feature.enabled?(:create_user_details_all_user_creation, Feature.current_request)
        super
      else
        user.user_detail
      end
    end

    def signup_params
      super + [:skip_confirmation]
    end

    override :assign_skip_confirmation_from_settings?
    def assign_skip_confirmation_from_settings?
      user_params[:skip_confirmation].blank?
    end
  end
end

Users::RegistrationsBuildService.prepend_mod
