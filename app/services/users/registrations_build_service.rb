# frozen_string_literal: true

module Users
  class RegistrationsBuildService < BuildService
    extend ::Gitlab::Utils::Override

    private

    override :allow_caller_to_request_skip_confirmation?
    def allow_caller_to_request_skip_confirmation?
      true
    end

    override :assign_skip_confirmation_from_settings?
    def assign_skip_confirmation_from_settings?(user_params)
      user_params[:skip_confirmation].blank?
    end
  end
end
