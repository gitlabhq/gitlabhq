# frozen_string_literal: true

module VerifiesWithEmailHelper
  include Gitlab::Utils::StrongMemoize

  RESEND_COOLDOWN_PERIOD = 60.seconds

  # Used by frontend to decide if we should render the "skip for now" button
  def permitted_to_skip_email_otp_in_warning_period?(user)
    Feature.enabled?(:email_based_mfa, user) &&
      !user.two_factor_enabled? &&
      trusted_ip_address?(user) &&
      !treat_as_locked?(user) &&
      in_email_otp_warning_period?(user)
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

  # Returns a Unix ms timestamp, after which the frontend can show the
  # "Resend" button. This is not used as a security control or rate
  # limit.
  def show_email_otp_resend_after(user)
    return unless user.email_otp_last_sent_at

    (user.email_otp_last_sent_at + RESEND_COOLDOWN_PERIOD).to_i * 1000
  end

  private

  def in_email_otp_warning_period?(user)
    return false unless user.email_otp_required_after.present?

    user.email_otp_required_after.future? &&
      user.email_otp_required_after <= 7.days.from_now
  end
end
