# frozen_string_literal: true

module VerifiesWithEmailHelper
  include Gitlab::Utils::StrongMemoize

  # Used by frontend to decide if we should render the "skip for now" button
  def permitted_to_skip_email_otp_in_grace_period?(user)
    Feature.enabled?(:email_based_mfa, user) &&
      !user.two_factor_enabled? &&
      trusted_ip_address?(user) &&
      !treat_as_locked?(user) &&
      in_email_otp_grace_period?(user)
  end

  def trusted_ip_address?(user)
    AuthenticationEvent.initial_login_or_known_ip_address?(user, request.ip)
  end

  def treat_as_locked?(user)
    # A user can have #access_locked? return false, but we still want
    # to treat as locked during sign in if they were sent an unlock
    # token in the past.
    # See https://docs.gitlab.com/security/unlock_user/#gitlabcom-users
    # and https://gitlab.com/gitlab-org/gitlab/-/issues/560080.
    user.access_locked? || user.unlock_token.present?
  end

  private

  def in_email_otp_grace_period?(user)
    email_otp_required_after = user.email_otp_required_after

    return false unless email_otp_required_after.present?

    days_until_enrollment = (user.email_otp_required_after.to_date - Date.current).to_i
    days_until_enrollment.between?(1, 30)
  end
end
