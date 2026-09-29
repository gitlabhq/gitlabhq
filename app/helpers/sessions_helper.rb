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
    permitted_to_skip = permitted_to_skip_email_otp_in_warning_period?(user)

    {
      username: user.username,
      obfuscated_email: obfuscated_email(user.email),
      verify_path: session_path(:user),
      resend_path: users_resend_verification_code_path,
      skip_path: permitted_to_skip ? users_skip_verification_for_now_path : nil,
      show_resend_after: show_email_otp_resend_after(user)
    }
  end

  def fallback_to_email_otp_permitted?(user)
    user.email_based_otp_required? && !treat_as_locked?(user)
  end

  def passkey_authentication_data(params)
    {
      path: users_passkeys_sign_in_path,
      remember_me: params.fetch(:remember_me, '0')
    }
  end

  def two_factor_authentication_app_data(user:, params:, admin_mode: false)
    target_path = admin_mode ? admin_session_path : user_session_path
    render_remember_me = admin_mode ? false : remember_me_enabled?
    user_params = params[:user].presence || params
    # Email OTP is a sign-in fallback that is not offered during admin-mode re-authentication.
    email_otp_available = !admin_mode && fallback_to_email_otp_permitted?(user)

    data = {
      path: target_path,
      admin_mode: admin_mode.to_s,
      active_method: params[:two_factor_method].presence,
      remember_me: user_params.fetch(:remember_me, 0),
      remember_me_enabled: render_remember_me.to_s,
      totp_enabled: user.two_factor_otp_enabled?.to_s,
      webauthn_enabled: user.can_use_existing_webauthn_authenticator_for_2fa?.to_s,
      email_enabled: email_otp_available.to_s
    }

    if email_otp_available
      data[:send_email_otp_path] = users_fallback_to_email_otp_path
      # email_code.vue reads only these four; skip_path / show_resend_after are unused on the
      # 2FA screen, and verification_data stays whole for the identity-verification flow that
      # renders email_verification.vue.
      data[:email_verification_data] =
        verification_data(user).slice(:obfuscated_email, :verify_path, :resend_path, :username).to_json
    end

    data
  end

  def show_passkey_immediately?
    true
  end

  def sign_in_form_app_data
    {
      sign_in_path: user_session_path,
      users_sign_in_path_path: users_sign_in_path_path,
      passkeys_sign_in_path: users_passkeys_sign_in_path,
      is_unconfirmed_email: unconfirmed_email?,
      new_user_confirmation_path: new_user_confirmation_path,
      new_password_path: new_user_password_path,
      show_captcha: captcha_enabled? || captcha_on_login_required?,
      is_remember_me_enabled: remember_me_enabled?,
      show_passkey_immediately: show_passkey_immediately?
    }.to_json
  end
end

SessionsHelper.prepend_mod
