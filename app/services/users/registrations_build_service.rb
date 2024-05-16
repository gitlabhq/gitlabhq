# frozen_string_literal: true

module Users
  class RegistrationsBuildService < BuildService
    extend ::Gitlab::Utils::Override

    private

    override :build_user_detail
    def build_user_detail
      return unless Feature.enabled?(:create_user_details_with_user_creation, Feature.current_request)

      user.user_detail
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
