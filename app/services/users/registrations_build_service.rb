# frozen_string_literal: true

module Users
  class RegistrationsBuildService < BuildService
    extend ::Gitlab::Utils::Override

    private

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
