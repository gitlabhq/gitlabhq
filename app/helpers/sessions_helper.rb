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

  def fallback_to_email_otp_permitted?(user)
    Feature.enabled?(:email_based_mfa, user) &&
      user.email_otp_required_after&.past? &&
      !treat_as_locked?(user)
  end

  def webauthn_authentication_data(user:, params:, admin_mode: false)
    target_path = admin_mode ? admin_session_path : user_session_path
    render_remember_me = admin_mode ? false : remember_me_enabled?
    user_params = params[:user].presence || params
    remember_me_value = user_params.fetch(:remember_me, 0)

    send_email_otp_path = fallback_to_email_otp_permitted?(user) ? users_fallback_to_email_otp_path : nil

    data = {
      target_path: target_path,
      render_remember_me: render_remember_me.to_s,
      remember_me: remember_me_value,
      send_email_otp_path: send_email_otp_path,
      username: user.username
    }

    # This is additional data needed to complete the email verification workflow
    if send_email_otp_path
      verification_data_hash = verification_data(user)
      data[:email_verification_data] = {
        username: verification_data_hash[:username],
        obfuscatedEmail: verification_data_hash[:obfuscated_email],
        verifyPath: verification_data_hash[:verify_path],
        resendPath: verification_data_hash[:resend_path],
        skipPath: verification_data_hash[:skip_path]
      }.to_json
    end

    data
  end
end
