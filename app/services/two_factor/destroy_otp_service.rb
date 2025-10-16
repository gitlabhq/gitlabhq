# frozen_string_literal: true

module TwoFactor
  class DestroyOtpService < ::TwoFactor::BaseService
    def execute
      return error(_('You are not authorized to perform this action')) unless authorized?

      unless user.two_factor_otp_enabled?
        return error(_('This user does not have a one-time password authenticator registered.'))
      end

      result = disable_two_factor_otp

      if result[:status] == :success
        notify_on_success(user)

        unless user.two_factor_enabled?
          user.reset_backup_codes!
          notification_service.disabled_two_factor(user)
        end
      end

      result
    end

    private

    def authorized?
      can?(current_user, :disable_two_factor, user)
    end

    def disable_two_factor_otp
      ::Users::UpdateService.new(current_user, user: user).execute(&:disable_two_factor_otp!)
    end

    def notify_on_success(user)
      notification_service.disabled_two_factor(user, :otp)
    end
  end
end

TwoFactor::DestroyOtpService.prepend_mod
