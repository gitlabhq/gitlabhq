# frozen_string_literal: true

module Users
  module EmailOtpEnrollment
    extend ActiveSupport::Concern

    def can_modify_email_otp_enrollment?
      email_otp_enrollment_restriction.nil?
    end

    def email_otp_enrollment_restriction
      return :feature_disabled            unless Feature.enabled?(:email_based_mfa, self)
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
        Gitlab::CurrentSettings.require_minimum_email_based_otp_for_users_with_passwords? &&
        !two_factor_enabled?
    end

    # Ensures email_otp_required_after is in a valid state based on
    # the restrictions applied to the user (instance settings, group
    # policies, etc).
    #
    # Sets the value directly on user_detail because delegated attributes
    # don't propagate dirty state to the parent User model, which would
    # prevent changes from being saved.
    #
    # @param save [Boolean] whether to persist changes if
    #   email_otp_required_after is modified (default: false)
    def set_email_otp_required_after_based_on_restrictions(save: false)
      return unless Feature.enabled?(:email_based_mfa, self)

      if email_otp_required_after.nil? && must_require_email_otp?
        # Revert if being changed to nil, or set to Time.current if
        # it was always nil but shouldn't be
        user_detail.email_otp_required_after = user_detail.email_otp_required_after_was || Time.current
      elsif Gitlab::Auth::TwoFactorAuthVerifier.new(self).two_factor_authentication_required? && two_factor_enabled?
        # Email OTP has less security assurance than 2FA. Therefore,
        # don't allow Email OTP when 2FA is required & configured.
        user_detail.email_otp_required_after = nil
      end
      # If neither condition is true, email_otp_required_after does not
      # need to be modified.

      return unless user_detail.email_otp_required_after_changed?

      Gitlab::AppLogger.info(
        message: "set_email_otp_required_after_based_on_restrictions is modifying email_otp_required_after",
        change: { before: user_detail.email_otp_required_after_was, after: user_detail.email_otp_required_after },
        user_id: id
      )

      # Conditionally save the record, with error logging instead of
      # raising.
      return unless save && !user_detail.save

      Gitlab::AppLogger.warn(
        message: 'set_email_otp_required_after_based_on_restrictions failed to save',
        change: { before: user_detail.email_otp_required_after_was, after: user_detail.email_otp_required_after },
        errors: user_detail.errors.full_messages
      )
    end
  end
end
