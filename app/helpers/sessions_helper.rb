# frozen_string_literal: true

module SessionsHelper
  include Gitlab::Utils::StrongMemoize

  def unconfirmed_email?
    flash[:alert] == t(:unconfirmed, scope: [:devise, :failure])
  end

  def obfuscated_email(email)
    # Moved to Gitlab::Utils::Email in 15.9
    Gitlab::Utils::Email.obfuscated_email(email)
  end

  def remember_me_enabled?
    Gitlab::CurrentSettings.remember_me_enabled?
  end

  def unconfirmed_verification_email?(user)
    token_valid_from = ::Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES.minutes.ago
    user.email_reset_offered_at.nil? && user.pending_reconfirmation? && user.confirmation_sent_at >= token_valid_from
  end

  def verification_email(user)
    unconfirmed_verification_email?(user) ? user.unconfirmed_email : user.email
  end

  def verification_data(user)
    {
      username: user.username,
      obfuscated_email: obfuscated_email(verification_email(user)),
      verify_path: session_path(:user),
      resend_path: users_resend_verification_code_path,
      offer_email_reset: user.email_reset_offered_at.nil?.to_s,
      update_email_path: users_update_email_path
    }
  end
end
