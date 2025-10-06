# frozen_string_literal: true

module SessionsHelper
  include Gitlab::Utils::StrongMemoize
  include VerifiesWithEmailHelper

  def unconfirmed_email?
    flash[:alert] == t(:unconfirmed, scope: [:devise, :failure])
  end

  def obfuscated_email(email)
    # Moved to Gitlab::Utils::Email in 15.9
    Gitlab::Utils::Email.obfuscated_email(email)
  end

  def session_expire_modal_data
    { session_timeout: Gitlab::Auth::SessionExpireFromInitEnforcer.session_expires_at(session) * 1000,
      sign_in_url: new_session_url(:user, redirect_to_referer: 'yes') }
  end

  def remember_me_enabled?
    Gitlab::CurrentSettings.allow_user_remember_me?
  end

  def verification_data(user)
    permitted_to_skip = permitted_to_skip_email_otp_in_grace_period?(user)

    {
      username: user.username,
      obfuscated_email: obfuscated_email(user.email),
      verify_path: session_path(:user),
      resend_path: users_resend_verification_code_path,
      skip_path: permitted_to_skip ? users_skip_verification_for_now_path : nil
    }
  end
end
