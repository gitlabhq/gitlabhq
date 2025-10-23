# frozen_string_literal: true

module Users
  module EmailOtpEnrollment
    extend ActiveSupport::Concern

    def can_modify_email_otp_enrollment?
      email_otp_enrollment_restriction.nil?
    end

    def email_otp_enrollment_restriction
      return :uses_external_authenticator if password_automatically_set?

      # TwoFactorAuthVerifier provides Group, Global, and Admin 2FA
      # restriction logic
      reason = Gitlab::Auth::TwoFactorAuthVerifier.new(self).two_factor_authentication_reason
      return :"#{reason}_enforcement" if reason

      return :future_enforcement          if email_otp_required_after&.future?
      return :email_otp_required          if must_require_email_otp?

      nil
    end

    def must_require_email_otp?
      !password_automatically_set? &&
        !two_factor_enabled? &&
        Gitlab::CurrentSettings.require_minimum_email_based_otp_for_users_with_passwords?
    end
  end
end
